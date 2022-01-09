terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.66.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

resource "aws_codebuild_project" "go-stars" {
  name          = "go-stars"
  description   = "go-stars search engine"
  service_role  = "arn:aws:iam::776727604074:role/service-role/codebuild"
  # type          = "BUILD"

    artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE", "LOCAL_SOURCE_CACHE"]
  }


    environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "GITHUB_TOKEN"
      value = "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."
      type  = "PARAMETER_STORE"
    }
  }

 logs_config {
    cloudwatch_logs {
      group_name  = "go-stars_build"
    #   stream_name = "log-stream"
    }
  }


  source {
    type            = "GITHUB"
    location        = "https://github.com/prabhatsharma/go-stars.git"
    git_clone_depth = 0
  }

#   source_version = "master"
}

resource "aws_codebuild_webhook" "go-stars" {
  project_name = "go-stars"
  build_type   = "BUILD"
  filter_group {
    filter {
      type    = "EVENT"
      pattern = "PUSH"
    }

    filter {
      type    = "HEAD_REF"
      pattern = "^refs/tags/.*"
    }
  }
}

