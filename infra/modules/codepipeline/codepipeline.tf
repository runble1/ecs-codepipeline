resource "aws_codepipeline" "this" {
  name     = "${var.prefix}-${var.env}-pipeline"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.artifacts_store.id
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      category = "Source"
      configuration = {
        BranchName           = var.branch_name
        PollForSourceChanges = "false"
        RepositoryName       = var.repository_name
      }
      name             = var.repository_name
      provider         = "CodeCommit"
      owner            = "AWS"
      version          = "1"
      output_artifacts = ["source_output"]
      role_arn         = aws_iam_role.codepipeline_codecommit.arn
    }
  }

  /*
  stage {
    name = "Test"
    action {
      category = "Build"
      name     = "Secrets_Check"
      owner           = "AWS"
      version         = "1"
      provider        = "CodeBuild"

      input_artifacts = ["source_output"]

      configuration = {
        ProjectName = aws_codebuild_project.secrets_check.name
      }
      role_arn        = aws_iam_role.codepipeline_codebuild.arn
    }

    action {
      category = "Build"
      name     = "Dockle_Check"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"

      input_artifacts  = ["source_output"]
      output_artifacts = ["dockle_check_output"]

      configuration = {
        ProjectName = aws_codebuild_project.dockle_check.name
      }
      role_arn         = aws_iam_role.codepipeline_codebuild.arn
    }

    action {
      category = "Build"
      name     = "Trivy_Check"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.trivy_check.name
      }

      input_artifacts  = ["source_output"]
      output_artifacts = ["trivy_check_output"]

      role_arn         = aws_iam_role.codepipeline_codebuild.arn
    }
  }*/

  stage {
    name = "Build"
    action {
      category = "Build"
      name     = "ECR_Build"
      owner    = "AWS"
      provider = "CodeBuild"
      version  = "1"

      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.build.name
      }

      role_arn = aws_iam_role.codepipeline_codebuild.arn
    }
  }

  stage {
    name = "Deploy"
    action {
      category = "Deploy"
      name     = "Deploy"
      owner    = "AWS"
      provider = "ECS"
      version  = "1"

      input_artifacts = ["build_output"]

      configuration = {
        FileName    = "imagedefinitions.json"
        ClusterName = var.ecs_cluster_name
        ServiceName = var.ecs_service_name
      }

      role_arn = aws_iam_role.codepipeline_deploy.arn
    }
  }
}
