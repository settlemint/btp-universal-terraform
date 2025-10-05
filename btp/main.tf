
# Generate random secrets if not provided
resource "random_password" "jwt_signing_key" {
  count   = var.jwt_signing_key == null ? 1 : 0
  length  = 32
  special = false
}

resource "random_password" "ipfs_cluster_secret" {
  count   = var.ipfs_cluster_secret == null ? 1 : 0
  length  = 64
  special = false
}

resource "random_password" "state_encryption_key" {
  count   = var.state_encryption_key == null ? 1 : 0
  length  = 32
  special = false
}

locals {
  auto_values = {
    # Ingress basics (class + issuer annotation). Host remains user-provided via values.
    ingress = {
      enabled   = true
      className = try(var.ingress_tls.ingress_class, null)
      annotations = {
        "cert-manager.io/cluster-issuer" = try(var.ingress_tls.issuer_name, null)
      }
    }

    # Redis connection
    redis = {
      host     = try(var.redis.host, null)
      port     = try(var.redis.port, null)
      password = try(var.redis.password, null)
      tls      = try(var.redis.tls_enabled, false)
    }

    # PostgreSQL connection
    postgresql = {
      host     = try(var.postgres.host, null)
      port     = try(var.postgres.port, null)
      user     = try(var.postgres.username, null)
      password = try(var.postgres.password, null)
      database = try(var.postgres.database, null)
      ssl      = try(var.postgres.ssl_mode, "disable")
    }

    # Vault (address only; credentials should be provided via values for prod)
    vault = {
      address = try(var.secrets.vault_addr, null)
    }

    # Use cluster-wide ingress-nginx we installed separately; do not install another controller inside the platform release
    support = {
      ingress-nginx = {
        enabled = false
      }
      "ipfs-cluster" = {
        clusterSecret = coalesce(
          var.ipfs_cluster_secret,
          var.values_file != null ? try(yamldecode(file(var.values_file)).ipfsCluster.clusterSecret, null) : null,
          random_password.ipfs_cluster_secret[0].result
        )
      }
    }
  }

  license = {
    username       = var.license_username
    password       = var.license_password
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
        state = {
          credentials = {
            encryptionKey = coalesce(
              var.state_encryption_key,
              var.values_file != null ? try(yamldecode(file(var.values_file)).features.deploymentEngine.state.credentials.encryptionKey, null) : null,
              base64encode(random_password.state_encryption_key[0].result)
            )
            aws = {
              accessKeyId     = var.aws_access_key_id != null ? var.aws_access_key_id : ""
              secretAccessKey = var.aws_secret_access_key != null ? var.aws_secret_access_key : ""
              region          = "us-east-1"
            }
          }
          secretsProvider = "passphrase"
        }
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

    auth = {
      jwtSigningKey = coalesce(
        var.jwt_signing_key,
        var.values_file != null ? try(yamldecode(file(var.values_file)).auth.jwtSigningKey, null) : null,
        random_password.jwt_signing_key[0].result
      )
    }

    ipfsCluster = {
      clusterSecret = coalesce(
        var.ipfs_cluster_secret,
        var.values_file != null ? try(yamldecode(file(var.values_file)).ipfsCluster.clusterSecret, null) : null,
        random_password.ipfs_cluster_secret[0].result
      )
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
        signingKey = coalesce(
          var.jwt_signing_key,
          var.values_file != null ? try(yamldecode(file(var.values_file)).internal.authJWT.signingKey, null) : null,
          random_password.jwt_signing_key[0].result
        )
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

resource "helm_release" "btp" {
  name            = var.release_name
  namespace       = var.namespace
  chart           = var.chart
  version         = var.chart_version != "" ? var.chart_version : null
  atomic          = false
  cleanup_on_fail = false
  timeout         = 600

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
    var.postgres,
    var.redis,
    var.ingress_tls,
    var.object_storage
  ]
}
