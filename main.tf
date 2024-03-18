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

