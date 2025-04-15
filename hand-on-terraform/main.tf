############################
# IAM Role for SageMaker
############################
resource "aws_iam_role" "sagemaker_role" {
  name               = "sagemaker_execution_role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "sagemaker.amazonaws.com"
        }
      }
    ]
  })
}

############################
# Attach Managed Policies
############################
resource "aws_iam_policy_attachment" "sagemaker_policy_attachment" {
  name       = "sagemaker-policy-attachment"
  roles      = [aws_iam_role.sagemaker_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

resource "aws_iam_policy_attachment" "iam_full_access" {
  name       = "iam-full-access"
  roles      = [aws_iam_role.sagemaker_role.name]
  policy_arn = "arn:aws:iam::aws:policy/IAMFullAccess"
}

resource "aws_iam_policy_attachment" "aws_lambda_full_access" {
  name       = "aws-lambda-full-access"
  roles      = [aws_iam_role.sagemaker_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AWSLambda_FullAccess"
}

resource "aws_iam_policy_attachment" "amazon_bedrock_full_access" {
  name       = "amazon-bedrock-full-access"
  roles      = [aws_iam_role.sagemaker_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonBedrockFullAccess"
}

resource "aws_iam_policy_attachment" "amazon_dynamodb_full_access" {
  name       = "amazon-dynamodb-full-access"
  roles      = [aws_iam_role.sagemaker_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

############################
# Custom Bedrock Policy
############################
data "aws_iam_policy_document" "bedrock_policy_doc" {
  statement {
    effect = "Allow"
    actions = [
      "bedrock:*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "bedrock_policy" {
  name        = "SageMakerBedrockPolicy"
  description = "Allows SageMaker to call Amazon Bedrock APIs"
  policy      = data.aws_iam_policy_document.bedrock_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "bedrock_policy_attachment" {
  role       = aws_iam_role.sagemaker_role.name
  policy_arn = aws_iam_policy.bedrock_policy.arn
}

############################
# VPC and Subnet
############################
resource "aws_vpc" "sagemaker_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "sagemaker_subnet" {
  vpc_id                  = aws_vpc.sagemaker_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-2a"   # Adjust based on region
  map_public_ip_on_launch = true
}

############################
# SageMaker Domain
############################
resource "aws_sagemaker_domain" "sagemaker_domain" {
  domain_name             = "bora-sagemaker-domain"
  auth_mode               = "IAM"
  vpc_id                  = aws_vpc.sagemaker_vpc.id
  subnet_ids              = [aws_subnet.sagemaker_subnet.id]
  app_network_access_type = "PublicInternetOnly"

  # Default settings for user profiles
  default_user_settings {
    execution_role = aws_iam_role.sagemaker_role.arn

    jupyter_server_app_settings {
      default_resource_spec {
        instance_type = "system"
      }
    }
  }

  # Default settings for Studio Spaces
  default_space_settings {
    execution_role = aws_iam_role.sagemaker_role.arn

    jupyter_server_app_settings {
      default_resource_spec {
        instance_type = "system"
      }
    }
  }
}

############################
# SageMaker User Profile
############################
resource "aws_sagemaker_user_profile" "bora_user" {
  domain_id         = aws_sagemaker_domain.sagemaker_domain.id
  user_profile_name = "bora-user"

  user_settings {
    execution_role = aws_iam_role.sagemaker_role.arn

    jupyter_server_app_settings {
      default_resource_spec {
        instance_type = "system"
      }
    }
  }
}

############################
# SageMaker Studio Space
############################
resource "aws_sagemaker_space" "bora_jupyterlab_space" {
  domain_id  = aws_sagemaker_domain.sagemaker_domain.id
  space_name = "bora-jupyterlab-space"

  space_settings {
    jupyter_server_app_settings {
      default_resource_spec {
        instance_type = "system"
        # Optionally, you can specify a SageMaker image ARN and version ARN here if needed.
      }
    }
  }
}

############################
# Data Sources for ARN Building
############################
data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

############################
# Custom AOSS Policy Document
############################
data "aws_iam_policy_document" "aoss_policy_doc" {
  statement {
    effect = "Allow"
    actions = [
      "aoss:CreateSecurityPolicy",
      "aoss:UpdateSecurityPolicy",
      "aoss:DeleteSecurityPolicy",
      "aoss:DescribeSecurityPolicy",
      "aoss:ListSecurityPolicies"
    ]
    # Use a fully qualified ARN for AOSS collections
    resources = [
      "arn:${data.aws_partition.current.partition}:aoss:eu-west-2:${data.aws_caller_identity.current.account_id}:collection/*"
    ]
  }
}

resource "aws_iam_policy" "aoss_policy" {
  name        = "AOSSFullAccessPolicyForSageMaker"
  description = "Allows SageMaker to perform AOSS actions needed by Bedrock agents"
  policy      = data.aws_iam_policy_document.aoss_policy_doc.json
}

############################
# Attach the Custom AOSS Policy to the SageMaker Role
############################
resource "aws_iam_role_policy_attachment" "aoss_policy_attachment" {
  role       = aws_iam_role.sagemaker_role.name
  policy_arn = aws_iam_policy.aoss_policy.arn
}