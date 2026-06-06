data "aws_iam_role" "lab_role" {
  name = var.lab_role_name
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  services    = toset(["ui", "admin", "catalog", "carts", "checkout", "orders"])

  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )

  alb_services = {
    ui = {
      path_patterns = ["/*"]
      priority      = 500
      health_path   = "/health"
    }
    admin = {
      path_patterns = ["/admin/*", "/auth/*"]
      priority      = 100
      health_path   = "/health"
    }
    catalog = {
      path_patterns = ["/catalog/*"]
      priority      = 110
      health_path   = "/health"
    }
    carts = {
      path_patterns = ["/carts/*"]
      priority      = 120
      health_path   = "/health"
    }
    checkout = {
      path_patterns = ["/checkout/*"]
      priority      = 130
      health_path   = "/health"
    }
    orders = {
      path_patterns = ["/orders/*"]
      priority      = 140
      health_path   = "/health"
    }
  }
}

module "networking" {
  source = "../modules/networking"

  name_prefix          = local.name_prefix
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  tags                 = local.common_tags
}

module "security" {
  source = "../modules/security"

  name_prefix = local.name_prefix
  vpc_id      = module.networking.vpc_id
  tags        = local.common_tags
}

module "ecr" {
  source = "../modules/ecr"

  name_prefix = local.name_prefix
  services    = local.services
  tags        = local.common_tags
}

module "secrets" {
  source = "../modules/secrets"

  name_prefix    = local.name_prefix
  db_username    = var.db_username
  admin_username = "admin"
  tags           = local.common_tags
}

module "database" {
  source = "../modules/database"

  name_prefix        = local.name_prefix
  private_subnet_ids = module.networking.private_subnet_ids
  security_group_id  = module.security.rds_sg_id
  db_name            = "orders"
  username           = module.secrets.db_username
  password           = module.secrets.db_password
  instance_class     = var.db_instance_class
  tags               = local.common_tags
}

module "redis" {
  source = "../modules/redis"

  name_prefix        = local.name_prefix
  private_subnet_ids = module.networking.private_subnet_ids
  security_group_id  = module.security.redis_sg_id
  node_type          = var.redis_node_type
  tags               = local.common_tags
}

module "monitoring" {
  source = "../modules/monitoring"

  name_prefix       = local.name_prefix
  services          = local.services
  retention_in_days = 14
  tags              = local.common_tags
}

module "alb" {
  source = "../modules/alb"

  name_prefix           = local.name_prefix
  vpc_id                = module.networking.vpc_id
  public_subnet_ids     = module.networking.public_subnet_ids
  alb_security_group_id = module.security.alb_sg_id
  services              = local.alb_services
  tags                  = local.common_tags
}

locals {
  secret_arn = module.secrets.secret_arn
  alb_url    = "http://${module.alb.alb_dns_name}"
  db_host    = module.database.address
  db_port    = tostring(module.database.port)
  redis_url  = "redis://${module.redis.endpoint}:${module.redis.port}"

  service_definitions = {
    ui = {
      image         = "${module.ecr.repository_urls["ui"]}:${var.image_tag}"
      cpu           = var.service_cpu["ui"]
      memory        = var.service_memory["ui"]
      desired_count = var.service_desired_count["ui"]
      port          = 8080
      public        = true
      environment = {
        PORT                         = "8080"
        RETAIL_UI_ENDPOINTS_CATALOG  = local.alb_url
        RETAIL_UI_ENDPOINTS_CARTS    = local.alb_url
        RETAIL_UI_ENDPOINTS_CHECKOUT = local.alb_url
        RETAIL_UI_ENDPOINTS_ORDERS   = local.alb_url
      }
      secrets = {}
    }
    admin = {
      image         = "${module.ecr.repository_urls["admin"]}:${var.image_tag}"
      cpu           = var.service_cpu["admin"]
      memory        = var.service_memory["admin"]
      desired_count = var.service_desired_count["admin"]
      port          = 8080
      public        = true
      environment = {
        PORT    = "8080"
        DB_HOST = local.db_host
        DB_PORT = local.db_port
        DB_USER = var.db_username
      }
      secrets = {
        DB_PASSWORD      = "${local.secret_arn}:db_password::"
        ADMIN_USERNAME   = "${local.secret_arn}:admin_username::"
        ADMIN_PASSWORD   = "${local.secret_arn}:admin_password::"
        ADMIN_JWT_SECRET = "${local.secret_arn}:admin_jwt_secret::"
      }
    }
    catalog = {
      image         = "${module.ecr.repository_urls["catalog"]}:${var.image_tag}"
      cpu           = var.service_cpu["catalog"]
      memory        = var.service_memory["catalog"]
      desired_count = var.service_desired_count["catalog"]
      port          = 8080
      public        = true
      environment = {
        GIN_MODE                            = "release"
        RETAIL_CATALOG_PERSISTENCE_PROVIDER = "postgres"
        RETAIL_CATALOG_PERSISTENCE_ENDPOINT = module.database.endpoint
        RETAIL_CATALOG_PERSISTENCE_DB_NAME  = "catalogdb"
        RETAIL_CATALOG_PERSISTENCE_USER     = var.db_username
      }
      secrets = {
        RETAIL_CATALOG_PERSISTENCE_PASSWORD = "${local.secret_arn}:db_password::"
      }
    }
    carts = {
      image         = "${module.ecr.repository_urls["carts"]}:${var.image_tag}"
      cpu           = var.service_cpu["carts"]
      memory        = var.service_memory["carts"]
      desired_count = var.service_desired_count["carts"]
      port          = 8080
      public        = true
      environment = {
        PORT                      = "8080"
        CART_PERSISTENCE_PROVIDER = "postgres"
        CART_POSTGRES_HOST        = local.db_host
        CART_POSTGRES_PORT        = local.db_port
        CART_POSTGRES_DB          = "cartdb"
        CART_POSTGRES_USER        = var.db_username
      }
      secrets = {
        CART_POSTGRES_PASSWORD = "${local.secret_arn}:db_password::"
      }
    }
    checkout = {
      image         = "${module.ecr.repository_urls["checkout"]}:${var.image_tag}"
      cpu           = var.service_cpu["checkout"]
      memory        = var.service_memory["checkout"]
      desired_count = var.service_desired_count["checkout"]
      port          = 8080
      public        = true
      environment = {
        PORT                                  = "8080"
        RETAIL_CHECKOUT_PERSISTENCE_PROVIDER  = "redis"
        RETAIL_CHECKOUT_PERSISTENCE_REDIS_URL = local.redis_url
        RETAIL_CHECKOUT_ENDPOINTS_ORDERS      = local.alb_url
      }
      secrets = {}
    }
    orders = {
      image         = "${module.ecr.repository_urls["orders"]}:${var.image_tag}"
      cpu           = var.service_cpu["orders"]
      memory        = var.service_memory["orders"]
      desired_count = var.service_desired_count["orders"]
      port          = 8080
      public        = true
      environment = {
        GIN_MODE                           = "release"
        RETAIL_ORDERS_PERSISTENCE_ENDPOINT = module.database.endpoint
        RETAIL_ORDERS_PERSISTENCE_NAME     = "orders"
        RETAIL_ORDERS_PERSISTENCE_USERNAME = var.db_username
      }
      secrets = {
        RETAIL_ORDERS_PERSISTENCE_PASSWORD = "${local.secret_arn}:db_password::"
      }
    }
  }
}

module "ecs" {
  source = "../modules/ecs"

  name_prefix        = local.name_prefix
  aws_region         = var.aws_region
  private_subnet_ids = module.networking.private_subnet_ids
  security_group_id  = module.security.ecs_sg_id
  lab_role_arn       = data.aws_iam_role.lab_role.arn
  log_group_names    = module.monitoring.log_group_names
  target_group_arns  = module.alb.target_group_arns
  services           = local.service_definitions
  tags               = local.common_tags

  depends_on = [module.secrets]
}

module "lambda" {
  source = "../modules/lambda"

  name_prefix        = local.name_prefix
  lab_role_arn       = data.aws_iam_role.lab_role.arn
  subnet_ids         = module.networking.private_subnet_ids
  security_group_ids = [module.security.lambda_sg_id]
  tags               = local.common_tags
}
