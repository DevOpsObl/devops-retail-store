aws_region    = "us-east-1"
project_name  = "devops-retail-store"
environment   = "prod"
lab_role_name = "LabRole"

vpc_cidr             = "10.60.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs  = ["10.60.1.0/24", "10.60.2.0/24"]
private_subnet_cidrs = ["10.60.11.0/24", "10.60.12.0/24"]

image_tag         = "latest"
db_username       = "retail_user"
db_instance_class = "db.t3.micro"
redis_node_type   = "cache.t3.micro"

service_desired_count = {
  ui       = 2
  admin    = 1
  catalog  = 2
  cart     = 2
  checkout = 2
  orders   = 2
}

tags = {
  Course = "TallerDevOps"
}
