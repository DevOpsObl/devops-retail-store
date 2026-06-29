aws_region    = "us-east-1"
project_name  = "devops-retail-store"
environment   = "dev"
lab_role_name = "LabRole"

vpc_cidr             = "10.40.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs  = ["10.40.1.0/24", "10.40.2.0/24"]
private_subnet_cidrs = ["10.40.11.0/24", "10.40.12.0/24"]

image_tag         = "latest"
db_username       = "retail_user"
db_instance_class = "db.t3.micro"
redis_node_type   = "cache.t3.micro"

tags = {
  Course = "TallerDevOps"
}
