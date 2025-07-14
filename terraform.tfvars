region          = "us-east-2"
backend_bucket  = "amruta-tfstate-bucket2"
backend_region  = "us-east-2"
dynamodb_table  = "terraform-lock2"
project         = "amruta-cloudops"
vpc_cidr        = "10.0.0.0/16"
public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]
azs             = ["us-east-2a", "us-east-2b"]
db_user         = "adminuser"
db_pass         = "StrongPass123!"
log_bucket      = "amruta-log-bucket2"

