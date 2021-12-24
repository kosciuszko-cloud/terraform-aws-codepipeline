resource "aws_codepipeline" "api" {
  name     = var.branch_name
  role_arn = var.cicd_role_arn

  artifact_store {
    location = var.cicd_bucket
    type     = "S3"
  }

  stage {
    name = "trigger"

    action {
      name             = "trigger"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      namespace        = "trigger"
      output_artifacts = ["code_bundle"]
      configuration    = {
        RepositoryName = var.product_name
        BranchName     = var.branch_name
      }
    }

  }

  stage {
    name = "build"

    action {
      name             = "plan"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["code_bundle"]
      version          = "1"
      configuration    = {
        ProjectName          = "docker_build"
        EnvironmentVariables = jsonencode([
          {
            name  = "env"
            value = var.env
          },
          {
            name  = "region"
            value = var.region
          },
          {
            name  = "registry"
            value = "${var.target_account_id}.dkr.ecr.${var.region}.amazonaws.com"
          },
          {
            name  = "image"
            value = "${var.env}_api"
          }
        ])
      }
    }

  }
}
