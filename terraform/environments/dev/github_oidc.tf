# Lets GitHub Actions authenticate to AWS with short-lived tokens (OIDC)
# instead of long-lived access keys stored as GitHub secrets.
#
# NOTE: an AWS account can only have ONE OIDC provider per URL. If you
# have used GitHub OIDC before in this account, `terraform apply` will
# fail with "EntityAlreadyExists". In that case, delete the
# aws_iam_openid_connect_provider block and reference your existing
# provider's ARN instead.
#
# IMMUTABLE SUBJECT CLAIMS: repos created (or renamed/transferred) on
# GitHub.com after mid-2026 get numeric owner/repo IDs baked into the
# OIDC token's "sub" claim - e.g. repo:owner@169626619/repo@1393720564
# instead of the older repo:owner/repo. If your trust policy uses the
# old name-only format but your repo emits the new one, every workflow
# run fails with a generic "Not authorized to perform
# sts:AssumeRoleWithWebIdentity" error that gives no hint this is the
# cause. Check which format your repo emits at:
#   https://github.com/<owner>/<repo>/settings/actions/oidc-configuration
# Get the two numeric IDs with:
#   curl -s https://api.github.com/repos/OWNER/REPO | python3 -c "import json,sys; d=json.load(sys.stdin); print('owner_id =', d['owner']['id']); print('repo_id  =', d['id'])"

variable "github_repo" {
  description = "Your GitHub repo in owner/name form, e.g. pjoshi/devops-lab. Set in terraform.tfvars."
  type        = string
}

variable "github_owner_id" {
  description = "Numeric GitHub owner/org ID (immutable subject claims). See the comment above for how to get this."
  type        = string
}

variable "github_repo_id" {
  description = "Numeric GitHub repository ID (immutable subject claims). See the comment above for how to get this."
  type        = string
}

data "aws_caller_identity" "current" {}

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd",
  ]
}

resource "aws_iam_role" "github_deploy" {
  name = "${var.project_name}-${var.environment}-github-deploy"

  # Only workflows running on the main branch of YOUR repo can assume this role.
  # Uses the immutable subject format - see the comment block above the
  # variables at the top of this file if this ever needs troubleshooting.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = ["sts:AssumeRoleWithWebIdentity", "sts:TagSession"]
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub" = "repo:${split("/", var.github_repo)[0]}@${var.github_owner_id}/${split("/", var.github_repo)[1]}@${var.github_repo_id}:ref:refs/heads/main"
        }
      }
    }]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-github-deploy"
    Environment = var.environment
  }
}

# Least privilege: push images to ONE repo, and run shell commands on
# instances via SSM. Nothing else.
resource "aws_iam_role_policy" "github_deploy" {
  name = "deploy-permissions"
  role = aws_iam_role.github_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "EcrLogin"
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        Sid    = "EcrPush"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
        ]
        Resource = module.ecr.repository_arn
      },
      {
        Sid      = "FindInstance"
        Effect   = "Allow"
        Action   = "ec2:DescribeInstances"
        Resource = "*"
      },
      {
        Sid    = "RunDeployCommand"
        Effect = "Allow"
        Action = "ssm:SendCommand"
        Resource = [
          "arn:aws:ssm:${var.aws_region}::document/AWS-RunShellScript",
          "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*",
        ]
      },
      {
        Sid      = "ReadCommandResult"
        Effect   = "Allow"
        Action   = ["ssm:GetCommandInvocation", "ssm:ListCommandInvocations"]
        Resource = "*"
      },
    ]
  })
}

output "github_deploy_role_arn" {
  description = "Save this as the AWS_ROLE_ARN secret in your GitHub repo"
  value       = aws_iam_role.github_deploy.arn
}