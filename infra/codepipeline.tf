resource "aws_codepipeline" "infra" {
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
      output_artifacts = ["plan_output"]
      version          = "1"
      configuration    = {
        ProjectName          = "terraform_plan"
        EnvironmentVariables = jsonencode([
          {
            name  = "env"
            value = var.env
          },
          {
            name  = "target_account_id"
            value = var.target_account_id
          }
        ])
      }
    }

  }

  stage {
    name = "deploy"

    action {
      name      = "approve"
      category  = "Approval"
      owner     = "AWS"
      provider  = "Manual"
      version   = "1"
      run_order = 1
    }

    action {
      name             = "apply"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["plan_output"]
      output_artifacts = ["apply_output"]
      version          = "1"
      run_order        = 2
      configuration    = {
        ProjectName          = "terraform_apply"
        EnvironmentVariables = jsonencode([
          {
            name  = "env"
            value = var.env
          },
          {
            name  = "target_account_id"
            value = var.target_account_id
          }
        ])
      }
    }

  }
}
