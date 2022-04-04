
locals {
  resource_name_prefix = "${var.environment}-${var.resource_tag_name}"

  tags = {
    Environment = var.environment
    Name        = var.resource_tag_name
  }
}


resource "aws_s3_bucket" "_" {
  bucket = "${local.resource_name_prefix}-${var.pipeline_artifact_bucket}"
  # acl    = "private"
}

resource "aws_s3_bucket_acl" "_" {
  bucket = aws_s3_bucket._.id
  acl    = "private"
}


module "aws_iam" {
  source            = "../aws_iam"
  environment       = var.environment
  region            = var.region
  resource_tag_name = var.resource_tag_name

  assume_role_policy = file("${path.root}/policies/code_pipeline_assume_role.json")
  template           = file("${path.root}/policies/cicd_policy.json")
  role_name          = "${var.cicd_name}-pipeline-role"
  policy_name        = "${var.cicd_name}-pipeline-policy"
  role_vars          = {}
}


module "aws_iam_codebuild" {
  source            = "../aws_iam"
  environment       = var.environment
  region            = var.region
  resource_tag_name = var.resource_tag_name

  assume_role_policy = file("${path.root}/policies/code_build_assume_role.json")
  template           = file("${path.root}/policies/cicd_policy.json")
  role_name          = "${var.cicd_name}-codebuild-role"
  policy_name        = "${var.cicd_name}-codebuild-policy"
  role_vars          = {}
}

resource "aws_codebuild_project" "sam_test" {
  name        = "${local.resource_name_prefix}-codebuild-test"
  description = "Plan state for terraform"

  service_role = module.aws_iam_codebuild.role_arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    # registry_credential {
    #   credential          = var.dockerhub_credentials
    #   credential_provider = "SECRETS_MANAGER"
    # }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = file("${path.module}/buildspec/test_buildspec.yml")
  }
}

resource "aws_codebuild_project" "tf_plan" {
  name        = "${local.resource_name_prefix}-codebuild-plan"
  description = "Plan state for terraform"

  service_role = module.aws_iam_codebuild.role_arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "hashicorp/terraform:latest"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "SERVICE_ROLE"

    # registry_credential {
    #   credential          = var.dockerhub_credentials
    #   credential_provider = "SECRETS_MANAGER"
    # }

  }

  source {
    type      = "CODEPIPELINE"
    buildspec = file("${path.module}/buildspec/plan_buildspec.yml")
  }
}

resource "aws_codebuild_project" "tf_apply" {
  name        = "${local.resource_name_prefix}-codebuild-apply"
  description = "Apply state for terraform"

  service_role = module.aws_iam_codebuild.role_arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "hashicorp/terraform:latest"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "SERVICE_ROLE"

    # registry_credential {
    #   credential          = var.dockerhub_credentials
    #   credential_provider = "SECRETS_MANAGER"
    # }

  }

  source {
    type      = "CODEPIPELINE"
    buildspec = file("${path.module}/buildspec/apply_buildspec.yml")
  }

}


resource "aws_codepipeline" "_" {

  name     = "${local.resource_name_prefix}-cicd"
  role_arn = module.aws_iam.role_arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket._.bucket
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["tf-code"]
      configuration = {
        FullRepositoryId     = "duc-hectre/terraform-aws-sam-example-1"
        BranchName           = "main"
        ConnectionArn        = var.codestar_connector_credentials
        OutputArtifactFormat = "CODE_ZIP"
        DetectChanges        = true
      }
    }
  }

  stage {
    name = "Test"
    action {
      name            = "Test"
      category        = "Test"
      provider        = "CodeBuild"
      version         = "1"
      owner           = "AWS"
      input_artifacts = ["tf-code"]
      # output_artifacts = ["tf-code-sam-build"]
      configuration = {
        ProjectName = aws_codebuild_project.sam_test.name
      }
    }
  }

  stage {
    name = "Plan"
    action {
      name            = "Build"
      category        = "Build"
      provider        = "CodeBuild"
      version         = "1"
      owner           = "AWS"
      input_artifacts = ["tf-code"]
      configuration = {
        ProjectName = aws_codebuild_project.tf_plan.name
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Build"
      provider        = "CodeBuild"
      version         = "1"
      owner           = "AWS"
      input_artifacts = ["tf-code"]
      configuration = {
        ProjectName = aws_codebuild_project.tf_apply.name
      }
    }
  }
}
