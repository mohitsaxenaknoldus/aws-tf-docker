resource "aws_ecs_cluster" "my_cluster" {
  name = "my-cluster"
}

resource "aws_ecs_task_definition" "my_task_definition" {
  family                = "my-task"
  container_definitions = <<DEFINITION
[
  {
    "name": "my-container",
    "image": "${aws_ecr_repository.my_repo.repository_url}:latest",
    "memory": 512,
    "cpu": 256,
    "portMappings": [
      {
        "containerPort": 3000,
        "hostPort": 3000,
        "protocol": "tcp"
      }
    ]
  }
]
DEFINITION
}

resource "aws_ecs_service" "my_service" {
  name            = "my-service"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.my_task_definition.arn
  desired_count   = 1

  network_configuration {
    subnets          = ["subnet-6e132a43", "subnet-8bf51cc3"] # Update with your subnet IDs
    security_groups  = ["sg-bd6ebac2"]                        # Update with your security group IDs
    assign_public_ip = true
  }

  depends_on = [aws_ecs_cluster.my_cluster]
}

resource "aws_ecr_repository" "my_repo" {
  name = "my-repo"
}

resource "aws_codebuild_project" "docker_build_project" {
  name       = "docker-build-project"
  description = "CodeBuild project to build Dockerfile and push image to ECR"
  service_role = aws_iam_role.codebuild_role.arn
  artifacts {
    type = "NO_ARTIFACTS"
  }
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }
  source {
    type            = "NO_SOURCE"
    buildspec       = "buildspec.yml"
  }
}

resource "aws_iam_role" "codebuild_role" {
  name = "codebuild-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "codebuild_policy_attachment" {
  name       = "codebuild-policy-attachment"
  roles      = [aws_iam_role.codebuild_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess"  # This policy provides full access to CodeBuild, adjust permissions as needed
}