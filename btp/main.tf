
# Constants for Helm deployment
locals {
  helm_timeout_seconds = 900 # 15 minutes (large chart with many components)
}

locals {
  # Parse values file once if provided
  values_from_file = var.values_file != null ? yamldecode(file(var.values_file)) : {}

  # Secret management with clear precedence:
  # 1. Explicit variable (REQUIRED)
  # 2. Values file
  jwt_signing_key = coalesce(
    var.jwt_signing_key,
    try(local.values_from_file.auth.jwtSigningKey, null)
  )

  ipfs_cluster_secret = coalesce(
    var.ipfs_cluster_secret,
    try(local.values_from_file.support["ipfs-cluster"].sharedSecret, null)
  )

  state_encryption_key = coalesce(
    var.state_encryption_key,
    try(local.values_from_file.features.deploymentEngine.state.credentials.encryptionKey, null)
  )

  internal_auth_jwt_signing_key = coalesce(
    var.jwt_signing_key,
    try(local.values_from_file.internal.authJWT.signingKey, null)
  )

  dns_config              = var.dns
  dns_tls_hosts           = var.dns != null ? var.dns.tls_hosts : null
  dns_tls_secret_name     = var.dns != null ? var.dns.tls_secret_name : null
  dns_ingress_annotations = var.dns != null && can(var.dns.ingress_annotations) && var.dns.ingress_annotations != null ? var.dns.ingress_annotations : {}
  dns_ssl_redirect        = var.dns != null && can(var.dns.ssl_redirect) ? var.dns.ssl_redirect : null
  default_ingress_host    = coalesce(var.base_domain, "btp.local")
  ingress_host            = coalesce(var.dns != null ? var.dns.hostname : null, local.default_ingress_host)
  ingress_tls_hosts       = distinct(local.dns_tls_hosts != null && length(local.dns_tls_hosts) > 0 ? local.dns_tls_hosts : [local.ingress_host])
  ingress_tls_secret_name = coalesce(local.dns_tls_secret_name, format("%s-tls", var.release_name))
  ingress_annotations = merge(
    {
      "cert-manager.io/cluster-issuer" = try(var.ingress_tls.issuer_name, "letsencrypt-prod")
    },
    local.dns_ssl_redirect != null ? { "nginx.ingress.kubernetes.io/ssl-redirect" = tostring(local.dns_ssl_redirect) } : {},
    local.dns_ingress_annotations
  )
  grafana_ingress_host         = format("grafana.%s", local.ingress_host)
  ipfs_ingress_host            = format("ipfs.%s", local.ingress_host)
  deployment_engine_connection_url = (
    try(trimspace(var.object_storage.bucket), "") != "" ?
    format("s3://%s", trimspace(var.object_storage.bucket)) :
    null
  )
  # Dynamic dependency values - auto-injected from module outputs
  # These values are built from the normalized outputs of dependency modules
  # and work regardless of mode (aws/azure/gcp/k8s/byo)
  dependency_values = {
    # Ingress configuration from ingress_tls module
    ingress = {
      enabled     = true
      className   = try(var.ingress_tls.ingress_class, "nginx")
      host        = local.ingress_host
      path        = "/"
      pathType    = "Prefix"
      annotations = local.ingress_annotations
      # Enable TLS and cert-manager for automatic certificate provisioning
      tls = length(local.ingress_tls_hosts) > 0 ? [{
        secretName = local.ingress_tls_secret_name
        hosts      = local.ingress_tls_hosts
      }] : []
      certManager = {
        enabled = true
        issuer  = try(var.ingress_tls.issuer_name, "letsencrypt-prod")
      }
    }

    # PostgreSQL connection - normalized across all providers
    postgresql = {
      enabled  = true
      host     = var.postgres.host
      port     = var.postgres.port
      user     = var.postgres.username # Chart expects 'user' not 'username'
      password = var.postgres.password
      database = var.postgres.database
      sslMode  = "require" # AWS RDS requires SSL
    }

    # Redis connection - normalized across all providers
    redis = {
      enabled  = true
      host     = var.redis.host
      port     = var.redis.port
      password = var.redis.password
      scheme   = var.redis.scheme
      tls      = var.redis.tls_enabled
    }

    # Object Storage (S3/MinIO/etc) - normalized across all providers
    objectStorage = {
      enabled      = true
      endpoint     = var.object_storage.endpoint
      bucket       = var.object_storage.bucket
      accessKey    = var.object_storage.access_key
      secretKey    = var.object_storage.secret_key
      region       = var.object_storage.region
      usePathStyle = var.object_storage.use_path_style
    }

    # Vault / Secrets Manager - normalized across all providers
    vault = {
      enabled = var.secrets.vault_addr != null
      address = var.secrets.vault_addr
      # Token should be provided via values for prod, or use k8s auth
      token = var.secrets.token != null ? var.secrets.token : null
    }

    # Use cluster-wide ingress-nginx we installed separately
    # Note: Don't set support here - it's set in dev_defaults to avoid merge conflicts
  }

  # OAuth provider fragments (currently Cognito + optional Google override)
  oauth_cognito_providers = var.oauth.issuer != null ? {
    cognito = {
      enabled      = true
      clientID     = var.oauth.client_id
      clientSecret = var.oauth.client_secret
      issuer       = var.oauth.issuer
    }
  } : {}

  google_oauth_providers = var.google_oauth_client_id != null && var.google_oauth_client_secret != null ? {
    google = {
      enabled      = true
      clientID     = var.google_oauth_client_id
      clientSecret = var.google_oauth_client_secret
    }
  } : {}

  auth_providers = merge(local.oauth_cognito_providers, local.google_oauth_providers)

  auth_values = {
    auth = merge(
      {
        jwtSigningKey = local.jwt_signing_key
      },
      length(local.auth_providers) > 0 ? { providers = local.auth_providers } : {}
    )
  }

  # Combine all auto-injected values
  auto_values = merge(
    local.dependency_values,
    local.auth_values
  )

  license = {
    username       = var.license_username
    password       = var.license_password
    accountName    = var.license_username # Harbor account name
    accountToken   = var.license_password # Harbor account token
    signature      = var.license_signature
    email          = var.license_email
    expirationDate = var.license_expiration_date
  }
  license_filtered = { for k, v in local.license : k => v if v != null }

  # Ensure pods can pull from the OCI registry via chart-managed image pull secrets
  image_pull_creds = {
    imagePullCredentials = {
      registries = {
        harbor = {
          enabled     = local.registry_host != null
          registryUrl = coalesce(local.registry_host, "registry.example.com")
          username    = var.license_username
          password    = var.license_password
          email       = var.license_email
        }
        docker = {
          enabled     = false
          registryUrl = "docker.io"
          username    = var.license_username
          password    = var.license_password
          email       = var.license_email
        }
        ghcr = {
          enabled     = true
          registryUrl = "ghcr.io"
          username    = var.license_username
          password    = var.license_password
          email       = var.license_email
        }
      }
    }
  }

  # Required configuration for development environments
  dev_defaults = {

    features = {
      deploymentEngine = {
        # Platform hostname - controls ingress resources
        platform = {
          domain = {
            hostname = local.ingress_host
          }
        }
        state = merge(
          local.deployment_engine_connection_url != null ? {
            connectionUrl = local.deployment_engine_connection_url
          } : {},
          {
            credentials = merge(
              {
                encryptionKey = local.state_encryption_key
              },
              # Only include AWS credentials if both are provided
              var.aws_access_key_id != null && var.aws_secret_access_key != null ? {
                aws = {
                  accessKeyId     = var.aws_access_key_id
                  secretAccessKey = var.aws_secret_access_key
                  region          = coalesce(var.object_storage.region, "us-east-1")
                }
              } : {}
            )
            secretsProvider = "passphrase"
          }
        )
        targets = [{
          id       = "aws"
          name     = "AWS"
          icon     = "aws"
          disabled = false
          clusters = [{
            id   = "primary"
            name = "Primary"
            icon = "global"
            location = {
              lat = 50.8505
              lon = 4.3488
            }
            disabled = false
            namespace = {
              single = {
                enabled = true
                name    = var.deployment_namespace
              }
            }
            connection = {
              sameCluster = {
                enabled = true
              }
            }
            domains = {
              service = {
                tls      = true
                hostname = local.ingress_host
                certManager = {
                  enabled = true
                  issuer  = try(var.ingress_tls.issuer_name, "letsencrypt-prod")
                }
              }
            }
            storage = {
              storageClass = "gp2"
            }
            ingress = {
              ingressClass = try(var.ingress_tls.ingress_class, "nginx")
            }
            capabilities = {
              mixedLoadBalancers = true
              p2pLoadBalancers   = false
              nodePorts = {
                enabled = true
                range = {
                  min = 30000
                  max = 32767
                }
              }
            }
          }]
        }]
      }
    }

    # postgresql config now provided via values file

    vault = {
      enabled = false
    }

    # auth.jwtSigningKey is now set via jwt_auth_values to avoid merge conflicts with oauth

    # Storage configuration for platform components
    support = {
      ingress-nginx = {
        enabled = true # Use cluster-wide ingress-nginx installed separately
      }
      ipfs-cluster = {
        # IPFS cluster secret must be 64-char hex - passed to subchart as sharedSecret
        sharedSecret = local.ipfs_cluster_secret
        cluster = {
          storage = {
            storageClassName = "gp2"
          }
        }
        ipfs = {
          storage = {
            storageClassName = "gp2"
          }
        }
        ingress = {
          enabled     = true
          className   = "settlemint-nginx"
          annotations = local.ingress_annotations
          hosts = [{
            host = local.ipfs_ingress_host
            paths = [{
              path     = "/"
              pathType = "Prefix"
            }]
          }]
        }
      }
    }

    # Observability storage - both Grafana and Victoria Metrics
    observability = {
      # Disable node-exporter to avoid port conflicts (not needed for AWS with external monitoring)
      prometheus-node-exporter = {
        enabled = true
      }
      grafana = merge(
        {
          persistence = {
            storageClassName = "gp2"
          },
          ingress = {
            enabled     = true
            className   = try(var.ingress_tls.ingress_class, "settlemint-nginx")
            annotations = local.ingress_annotations
            hosts       = [local.grafana_ingress_host]
          }
        },
        var.grafana_admin_password != null ? {
          auth = {
            username     = "admin"
            password     = var.grafana_admin_password
          }
        } : {}
      )
      victoria-metrics-single = {
        server = {
          persistentVolume = {
            storageClassName = "gp2" # Correct field name from the chart's values.yaml
          }
        }
      }
    }

    internal = {
      email = {
        enabled = false
        from    = "noreply@example.com"
        server = {
          host     = "smtp.example.com"
          port     = "587"
          user     = ""
          password = ""
        }
      }
      authJWT = {
        signingKey = local.internal_auth_jwt_signing_key
      }
    }
  }
}

resource "kubernetes_namespace" "btp" {
  count = var.create_namespace ? 1 : 0
  metadata {
    name = var.namespace
    labels = {
      "kots.io/app-slug" = "settlemint-platform"
    }
  }
}

resource "kubernetes_namespace" "deployments" {
  count = var.create_namespace && var.deployment_namespace != var.namespace ? 1 : 0

  metadata {
    name = var.deployment_namespace
    labels = {
      "kots.io/app-slug" = "settlemint-platform"
    }
  }
}

# Note: IPFS cluster secret is created by the Helm chart using values from ipfsCluster.clusterSecret
# The Terraform secret creation was removed as Helm overwrites it anyway

# Extract registry host from chart URL (e.g., oci://registry.example.com/... -> registry.example.com)
locals {
  registry_host = var.license_username != null && var.license_password != null ? (
    can(regex("^oci://([^/]+)/", var.chart)) ? regex("^oci://([^/]+)/", var.chart)[0] : null
  ) : null
}

# Login to OCI registry before pulling chart
resource "null_resource" "helm_registry_login" {
  count = local.registry_host != null ? 1 : 0

  triggers = {
    username      = var.license_username
    registry_host = local.registry_host
    # Don't include password in triggers to avoid unnecessary re-runs on password changes
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "${var.license_password}" | helm registry login ${local.registry_host} \
        --username "${var.license_username}" \
        --password-stdin
    EOT
  }
}

resource "helm_release" "btp" {
  name            = var.release_name
  namespace       = var.namespace
  chart           = var.chart
  version         = var.chart_version != "" ? var.chart_version : null
  atomic          = false
  cleanup_on_fail = false
  timeout         = local.helm_timeout_seconds

  values = var.values_file != null ? [
    yamlencode(merge(
      local.dev_defaults,
      local.image_pull_creds,
      length(local.license_filtered) > 0 ? { license = local.license_filtered } : {},
      local.auto_values,
      yamldecode(file(var.values_file)),
      var.values
    ))
    ] : [
    yamlencode(merge(
      local.dev_defaults,
      local.image_pull_creds,
      length(local.license_filtered) > 0 ? { license = local.license_filtered } : {},
      local.auto_values,
      var.values
    ))
  ]

  depends_on = [
    kubernetes_namespace.btp,
    kubernetes_namespace.deployments,
    null_resource.helm_registry_login,
    var.postgres,
    var.redis,
    var.ingress_tls,
    var.object_storage
  ]
}
