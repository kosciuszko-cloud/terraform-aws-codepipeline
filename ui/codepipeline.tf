resource "aws_codepipeline" "ui" {
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
      name             = "npm_build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["code_bundle"]
      output_artifacts = ["ui_bundle"]
      version          = "1"
      configuration    = {
        ProjectName          = "npm_build"
        EnvironmentVariables = jsonencode([
          {
            name  = "env"
            value = var.env
          },
          {
            name  = "region"
            value = var.region
          },
        ])
      }
    }

  }

  stage {
    name = "deploy"

    action {
      name             = "deploy"
      category         = "Deploy"
      owner            = "AWS"
      provider         = "S3"
      input_artifacts  = ["ui_bundle"]
      version          = "1"
      configuration    = {
        BucketName = "${var.env}-${var.product_name}-ui-bucket"
        Extract    = "true"
        CannedACL  = "bucket-owner-full-control"
      }
    }

  }
}
