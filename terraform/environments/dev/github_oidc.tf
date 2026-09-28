# Lets GitHub Actions authenticate to AWS with short-lived tokens (OIDC)
# instead of long-lived access keys stored as GitHub secrets.
#
# NOTE: an AWS account can only have ONE OIDC provider per URL. If you
# have used GitHub OIDC before in this account, `terraform apply` will
# fail with "EntityAlreadyExists". In that case, delete the
# aws_iam_openid_connect_provider block and reference your existing
# provider's ARN instead.

variable "github_repo" {
  description = "Your GitHub repo in owner/name form, e.g. pjoshi/devops-lab. Set in terraform.tfvars."
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
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRoleWithWebIdentity"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:ref:refs/heads/main"
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