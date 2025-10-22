# AWS EKS Cluster Implementation

locals {
  aws_vpc_id = var.aws.vpc_id != null ? var.aws.vpc_id : var.aws_context.vpc_id

  aws_subnet_ids = (
    length(try(var.aws.subnet_ids, [])) > 0 ?
    var.aws.subnet_ids :
    try(var.aws_context.subnet_ids, [])
  )

  aws_control_plane_subnet_ids = (
    length(try(var.aws.control_plane_subnet_ids, [])) > 0 ?
    var.aws.control_plane_subnet_ids :
    (
      length(local.aws_subnet_ids) > 0 ?
      local.aws_subnet_ids :
      try(var.aws_context.control_plane_subnet_ids, [])
    )
  )

  aws_security_group_ids = (
    length(try(var.aws.security_group_ids, [])) > 0 ?
    var.aws.security_group_ids :
    try(var.aws_context.security_group_ids, [])
  )
}

# IAM Role for EKS Cluster
resource "aws_iam_role" "eks_cluster" {
  count = var.mode == "aws" ? 1 : 0
  name  = "${var.aws.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })

  tags = merge(
    {
      Name        = "${var.aws.cluster_name}-cluster-role"
      ManagedBy   = "terraform"
      Application = "btp-k8s-cluster"
    },
    var.aws.tags
  )
}

# Attach required policies to cluster role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  count      = var.mode == "aws" ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster[0].name
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  count      = var.mode == "aws" ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster[0].name
}

# Security group for EKS cluster
resource "aws_security_group" "eks_cluster" {
  count       = var.mode == "aws" ? 1 : 0
  name        = "${var.aws.cluster_name}-cluster-sg"
  description = "Security group for EKS cluster control plane"
  vpc_id      = local.aws_vpc_id

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name        = "${var.aws.cluster_name}-cluster-sg"
      ManagedBy   = "terraform"
      Application = "btp-k8s-cluster"
    },
    var.aws.tags
  )
}

resource "aws_security_group_rule" "eks_cluster_nodeport_ingress" {
  count             = var.mode == "aws" ? 1 : 0
  description       = "Allow NodePort range for Kubernetes LoadBalancer targets"
  type              = "ingress"
  security_group_id = aws_eks_cluster.main[0].vpc_config[0].cluster_security_group_id
  from_port         = 30000
  to_port           = 32767
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "eks_cluster_kubelet_ingress" {
  count                    = var.mode == "aws" ? 1 : 0
  description              = "Allow control plane to reach kubelet"
  type                     = "ingress"
  security_group_id        = aws_eks_cluster.main[0].vpc_config[0].cluster_security_group_id
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_cluster[0].id
}

resource "aws_security_group_rule" "eks_cluster_https_ingress" {
  count                    = var.mode == "aws" ? 1 : 0
  description              = "Allow control plane to reach node webhooks"
  type                     = "ingress"
  security_group_id        = aws_eks_cluster.main[0].vpc_config[0].cluster_security_group_id
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_cluster[0].id
}
# KMS key for secrets encryption
resource "aws_kms_key" "eks" {
  count               = var.mode == "aws" && var.aws.enable_secrets_encryption && var.aws.kms_key_arn == null ? 1 : 0
  description         = "KMS key for EKS cluster secrets encryption"
  enable_key_rotation = true

  tags = merge(
    {
      Name        = "${var.aws.cluster_name}-kms"
      ManagedBy   = "terraform"
      Application = "btp-k8s-cluster"
    },
    var.aws.tags
  )
}

resource "aws_kms_alias" "eks" {
  count         = var.mode == "aws" && var.aws.enable_secrets_encryption && var.aws.kms_key_arn == null ? 1 : 0
  name          = "alias/${var.aws.cluster_name}-eks"
  target_key_id = aws_kms_key.eks[0].key_id
}

# EKS Cluster
resource "aws_eks_cluster" "main" {
  count    = var.mode == "aws" ? 1 : 0
  name     = var.aws.cluster_name
  role_arn = aws_iam_role.eks_cluster[0].arn
  version  = var.aws.cluster_version

  vpc_config {
    subnet_ids              = length(local.aws_control_plane_subnet_ids) > 0 ? local.aws_control_plane_subnet_ids : local.aws_subnet_ids
    endpoint_private_access = var.aws.endpoint_private_access
    endpoint_public_access  = var.aws.endpoint_public_access
    public_access_cidrs     = var.aws.public_access_cidrs
    security_group_ids      = [aws_security_group.eks_cluster[0].id]
  }

  enabled_cluster_log_types = var.aws.enabled_cluster_log_types

  dynamic "encryption_config" {
    for_each = var.aws.enable_secrets_encryption ? [1] : []
    content {
      provider {
        key_arn = var.aws.kms_key_arn != null ? var.aws.kms_key_arn : aws_kms_key.eks[0].arn
      }
      resources = ["secrets"]
    }
  }

  tags = merge(
    {
      Name        = var.aws.cluster_name
      ManagedBy   = "terraform"
      Application = "btp-k8s-cluster"
    },
    var.aws.tags
  )

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller,
  ]
}

# OIDC Provider for IRSA (IAM Roles for Service Accounts)
data "tls_certificate" "eks" {
  count = var.mode == "aws" && var.aws.enable_irsa ? 1 : 0
  url   = aws_eks_cluster.main[0].identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  count           = var.mode == "aws" && var.aws.enable_irsa ? 1 : 0
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks[0].certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main[0].identity[0].oidc[0].issuer

  tags = merge(
    {
      Name        = "${var.aws.cluster_name}-oidc"
      ManagedBy   = "terraform"
      Application = "btp-k8s-cluster"
    },
    var.aws.tags
  )
}

# IAM Role for Node Groups
resource "aws_iam_role" "eks_node_group" {
  count = var.mode == "aws" ? 1 : 0
  name  = "${var.aws.cluster_name}-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = merge(
    {
      Name        = "${var.aws.cluster_name}-node-group-role"
      ManagedBy   = "terraform"
      Application = "btp-k8s-cluster"
    },
    var.aws.tags
  )
}

# Attach required policies to node group role
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  count      = var.mode == "aws" ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group[0].name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  count      = var.mode == "aws" ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group[0].name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_policy" {
  count      = var.mode == "aws" ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group[0].name
}

# EBS CSI Driver Policy is now attached via IRSA role, not node role

# EKS Node Groups
resource "aws_eks_node_group" "main" {
  for_each = var.mode == "aws" ? var.aws.node_groups : {}

  cluster_name    = aws_eks_cluster.main[0].name
  node_group_name = each.key
  node_role_arn   = aws_iam_role.eks_node_group[0].arn
  subnet_ids      = local.aws_subnet_ids

  scaling_config {
    desired_size = each.value.desired_size
    min_size     = each.value.min_size
    max_size     = each.value.max_size
  }

  instance_types = each.value.instance_types
  capacity_type  = each.value.capacity_type
  disk_size      = each.value.disk_size

  labels = each.value.labels

  dynamic "taint" {
    for_each = each.value.taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  update_config {
    max_unavailable_percentage = 33
  }

  tags = merge(
    {
      Name        = "${var.aws.cluster_name}-${each.key}"
      ManagedBy   = "terraform"
      Application = "btp-k8s-cluster"
    },
    var.aws.tags
  )

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_policy,
  ]
}

# EKS Addons
resource "aws_eks_addon" "vpc_cni" {
  count                       = var.mode == "aws" ? 1 : 0
  cluster_name                = aws_eks_cluster.main[0].name
  addon_name                  = "vpc-cni"
  resolve_conflicts_on_update = "OVERWRITE"
  configuration_values = jsonencode({
    env = {
      ENABLE_PREFIX_DELEGATION = "true"
      WARM_PREFIX_TARGET       = "1"
    }
  })
}

resource "aws_eks_addon" "kube_proxy" {
  count                       = var.mode == "aws" ? 1 : 0
  cluster_name                = aws_eks_cluster.main[0].name
  addon_name                  = "kube-proxy"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "aws_eks_addon" "coredns" {
  count                       = var.mode == "aws" ? 1 : 0
  cluster_name                = aws_eks_cluster.main[0].name
  addon_name                  = "coredns"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.main]
}

# IAM role for EBS CSI Driver with IRSA
resource "aws_iam_role" "ebs_csi_driver" {
  count = var.mode == "aws" && var.aws.enable_ebs_csi_driver && var.aws.enable_irsa ? 1 : 0
  name  = "${var.aws.cluster_name}-ebs-csi-driver"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks[0].arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(aws_eks_cluster.main[0].identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          "${replace(aws_eks_cluster.main[0].identity[0].oidc[0].issuer, "https://", "")}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = {
    Name        = "${var.aws.cluster_name}-ebs-csi-driver"
    ManagedBy   = "terraform"
    Application = "eks-ebs-csi"
  }
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver_policy" {
  count      = var.mode == "aws" && var.aws.enable_ebs_csi_driver && var.aws.enable_irsa ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver[0].name
}

resource "aws_eks_addon" "ebs_csi_driver" {
  count                       = var.mode == "aws" && var.aws.enable_ebs_csi_driver ? 1 : 0
  cluster_name                = aws_eks_cluster.main[0].name
  addon_name                  = "aws-ebs-csi-driver"
  resolve_conflicts_on_update = "OVERWRITE"
  service_account_role_arn    = var.aws.enable_irsa ? aws_iam_role.ebs_csi_driver[0].arn : null

  depends_on = [
    aws_eks_node_group.main,
    aws_iam_role_policy_attachment.ebs_csi_driver_policy
  ]
}

# Local values for outputs
locals {
  aws_cluster_name      = var.mode == "aws" ? aws_eks_cluster.main[0].name : null
  aws_cluster_endpoint  = var.mode == "aws" ? aws_eks_cluster.main[0].endpoint : null
  aws_cluster_ca_cert   = var.mode == "aws" ? aws_eks_cluster.main[0].certificate_authority[0].data : null
  aws_cluster_version   = var.mode == "aws" ? aws_eks_cluster.main[0].version : null
  aws_oidc_provider_arn = var.mode == "aws" && var.aws.enable_irsa ? aws_iam_openid_connect_provider.eks[0].arn : null
  aws_oidc_provider_url = var.mode == "aws" && var.aws.enable_irsa ? replace(aws_eks_cluster.main[0].identity[0].oidc[0].issuer, "https://", "") : null

  # Generate kubeconfig for AWS EKS
  aws_kubeconfig = var.mode == "aws" ? yamlencode({
    apiVersion = "v1"
    kind       = "Config"
    clusters = [{
      name = aws_eks_cluster.main[0].name
      cluster = {
        server                     = aws_eks_cluster.main[0].endpoint
        certificate-authority-data = aws_eks_cluster.main[0].certificate_authority[0].data
      }
    }]
    contexts = [{
      name = aws_eks_cluster.main[0].name
      context = {
        cluster = aws_eks_cluster.main[0].name
        user    = aws_eks_cluster.main[0].name
      }
    }]
    current-context = aws_eks_cluster.main[0].name
    users = [{
      name = aws_eks_cluster.main[0].name
      user = {
        exec = {
          apiVersion = "client.authentication.k8s.io/v1beta1"
          command    = "aws"
          args = [
            "eks",
            "get-token",
            "--cluster-name",
            aws_eks_cluster.main[0].name,
            "--region",
            var.aws.region
          ]
        }
      }
    }]
  }) : null

  aws_provider_exec = var.mode == "aws" ? [{
    api_version = "client.authentication.k8s.io/v1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      aws_eks_cluster.main[0].name,
      "--region",
      var.aws.region
    ]
  }] : []
}

resource "null_resource" "cleanup_k8s_loadbalancers" {
  count = var.mode == "aws" ? 1 : 0

  triggers = {
    cluster_name = aws_eks_cluster.main[0].name
    region       = var.aws.region
  }

  provisioner "local-exec" {
    when       = destroy
    on_failure = continue
    command    = <<-EOT
      echo "🧹 Cleaning up Kubernetes LoadBalancers to prevent orphaned ENIs..."
      export KUBECONFIG="${path.root}/.terraform/kubeconfig-aws"
      kubectl delete svc -A --field-selector spec.type=LoadBalancer --timeout=120s 2>/dev/null || true
      echo "⏳ Waiting 30s for cloud provider to clean up network interfaces..."
      sleep 30
      echo "✅ Kubernetes LoadBalancer cleanup complete"
    EOT
  }
}

resource "null_resource" "cleanup_k8s_cni_enis" {
  count = var.mode == "aws" ? 1 : 0

  triggers = {
    cluster_name = aws_eks_cluster.main[0].name
    vpc_id       = local.aws_vpc_id
    region       = coalesce(var.aws.region, "us-east-1")
  }

  provisioner "local-exec" {
    when       = destroy
    on_failure = continue
    command    = <<-EOT
      set -euo pipefail
      export AWS_REGION="${self.triggers.region}"
      CLUSTER="${self.triggers.cluster_name}"
      VPC_ID="${self.triggers.vpc_id}"

      if [ -z "$CLUSTER" ] || [ -z "$VPC_ID" ]; then
        exit 0
      fi

      echo "🔍 Checking for residual ENIs in VPC $VPC_ID for cluster $CLUSTER"
      for _ in $(seq 1 6); do
        ENIS=$(aws ec2 describe-network-interfaces \
          --filters "Name=tag:cluster.k8s.amazonaws.com/name,Values=$CLUSTER" "Name=vpc-id,Values=$VPC_ID" \
          --query 'NetworkInterfaces[].NetworkInterfaceId' --output text || echo "")

        if [ -z "$ENIS" ] || [ "$ENIS" = "None" ]; then
          echo "✅ No residual ENIs detected"
          exit 0
        fi

        for ENI in $ENIS; do
          echo "🧹 Deleting ENI $ENI"
          aws ec2 delete-network-interface --network-interface-id "$ENI" || true
        done

        sleep 10
      done

      echo "⚠️ Some ENIs may remain; please verify manually."
    EOT
  }
}
