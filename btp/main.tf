
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

  # Dynamic dependency values - auto-injected from module outputs
  # These values are built from the normalized outputs of dependency modules
  # and work regardless of mode (aws/azure/gcp/k8s/byo)
  dependency_values = {
    # Ingress configuration from ingress_tls module
    ingress = {
      enabled   = true
      className = try(var.ingress_tls.ingress_class, "nginx")
      annotations = {
        "cert-manager.io/cluster-issuer" = try(var.ingress_tls.issuer_name, "letsencrypt-prod")
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

  # OAuth configuration (conditional - only if oauth module is enabled)
  # Note: This only adds the oidc section to auth, jwtSigningKey is added separately
  oauth_values = var.oauth.issuer != null ? {
    auth = {
      oidc = {
        enabled      = true
        issuer       = var.oauth.issuer
        clientId     = var.oauth.client_id
        clientSecret = var.oauth.client_secret
        scopes       = var.oauth.scopes
      }
    }
  } : {}

  # JWT signing key configuration - separate from oauth to avoid merge conflicts
  jwt_auth_values = {
    auth = {
      jwtSigningKey = local.jwt_signing_key
    }
  }

  # Combine all auto-injected values
  auto_values = merge(
    local.dependency_values,
    local.oauth_values,
    local.jwt_auth_values
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

  # Ensure pods can pull from Harbor via chart-managed image pull secrets
  image_pull_creds = {
    imagePullCredentials = {
      registries = {
        harbor = {
          enabled     = true
          registryUrl = "harbor.settlemint.com"
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
        state = merge(
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
                  region          = "us-east-1"
                }
              } : {}
            )
            secretsProvider = "passphrase"
          }
        )
        targets = [{
          clusters = [{
            domains = {
              service = {
                hostname = var.base_domain != null ? var.base_domain : "example.com"
                port     = 443
                protocol = "https"
              }
            }
            namespace = {
              single = {
                enabled = true
                name    = "deployments"
              }
            }
            location = {
              lat = 50.8505
              lon = 4.3488
            }
            storage = {
              storageClass = "local-path"
            }
            ingress = {
              ingressClass = "nginx"
            }
            connection = {
              sameCluster = {
                enabled = true
              }
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
            name = "default"
          }]
          name = "default"
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
        enabled = false # Use cluster-wide ingress-nginx installed separately
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
      }
    }

    # Observability storage - both Grafana and Victoria Metrics
    observability = {
      # Disable node-exporter to avoid port conflicts (not needed for AWS with external monitoring)
      prometheus-node-exporter = {
        enabled = false
      }
      grafana = {
        persistence = {
          storageClassName = "gp2"
        }
      }
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
  metadata { name = var.namespace }
}

# Note: IPFS cluster secret is created by the Helm chart using values from ipfsCluster.clusterSecret
# The Terraform secret creation was removed as Helm overwrites it anyway

# Extract registry host from chart URL (e.g., oci://harbor.settlemint.com/... -> harbor.settlemint.com)
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
    null_resource.helm_registry_login,
    var.postgres,
    var.redis,
    var.ingress_tls,
    var.object_storage
  ]
}
