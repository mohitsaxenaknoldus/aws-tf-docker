resource "aws_ecs_cluster" "my_cluster" {
  name = "my-cluster"
}

resource "aws_iam_role_policy_attachment" "aws-tf-docker-ecr-policy-attachment" {
  role       = aws_iam_role.aws-tf-docker-ecs_task_exec_role.name
  policy_arn = aws_iam_policy.aws-tf-docker-ecr-policy.arn
}

resource "aws_iam_policy" "aws-tf-docker-ecr-policy" {
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ],
      "Resource": "${aws_ecr_repository.my_repo.arn}"
    }
  ]
}
EOF
}

resource "aws_cloudwatch_log_group" "aws-tf-docker-build-logs" {
  name = "aws-tf-docker-build-logs"
}

resource "aws_iam_role" "aws-tf-docker-ecs_task_exec_role" {
  name                 = "aws-tf-docker-ecs_task_exec_role"
  max_session_duration = 10800
  assume_role_policy   = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_ecs_task_definition" "my_task_definition" {
  family             = "aws-tf-docker-task-def"
  memory             = "512"
  network_mode       = "awsvpc"
  cpu                = "256"
  execution_role_arn = aws_iam_role.aws-tf-docker-ecs_task_exec_role.arn
  requires_compatibilities = [
    "FARGATE",
  ]
  container_definitions = jsonencode([
    {
      cpu    = 10
      memory = 512
      secrets = [
      ]
      environment = [
      ]
      image = "${aws_ecr_repository.my_repo.repository_url}:latest"
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.aws-tf-docker-build-logs.name
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "aws-tf-docker"
        }
      }
      mountPoints = []
      name        = "aws-tf-docker-container"
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
          protocol      = "tcp"
        },
      ]
      volumesFrom = []
    },
  ])
}

resource "aws_ecs_service" "my_service" {
  name            = "my-service"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.my_task_definition.arn
  desired_count   = 1

  network_configuration {
    subnets         = ["subnet-6e132a43", "subnet-8bf51cc3"] # Update with your subnet IDs
    security_groups = ["sg-bd6ebac2"]                        # Update with your security group IDs
  }

  depends_on = [aws_ecs_cluster.my_cluster]
}

resource "aws_ecr_repository" "my_repo" {
  name = "my-repo"
}

resource "aws_codebuild_project" "docker_build_project" {
  name         = "docker-build-project"
  description  = "CodeBuild project to build Dockerfile and push image to ECR"
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
    type            = "GITHUB"
    location        = "https://github.com/mohitsaxenaknoldus/aws-tf-docker"
    git_clone_depth = 1
    git_submodules_config {
      fetch_submodules = false
    }
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
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess" # This policy provides full access to CodeBuild, adjust permissions as needed
}