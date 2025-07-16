Terraform CI/CD on AWS with Jenkins

This project automates the provisioning of a full AWS infrastructure using **Terraform** and manages deployments using Jenkins CI/CD pipelines.

# Features

-  VPC with public/private subnets
- NAT Gateway, Route Tables
- EC2 Auto Scaling Group (Windows Server 2019)
- Application Load Balancer (internal)
- RDS SQL Server (in private subnet)
- IAM roles for EC2 to access SSM + Secrets Manager
- CloudWatch metrics and alarms
-  Session Manager & Fleet Manager access (SSM agent setup)
-  Jenkins pipelines: `apply` and `destroy`
-  Bootstrap IIS + custom HTML via PowerShell script


# Directory Structure

terraform-cicd/
├── .gitignore
├── .terraform.lock.hcl         # Terraform dependency lock
├── Jenkinsfile                 # Main CI/CD pipeline
├── Jenkinsfile-destroy         # Pipeline for `terraform destroy`
├── README.md                   #  You are here,Read this to understand the project
├── main.tf                     # Main Terraform config
├── outputs.tf                  # Output variables
├── terraform.tfvars            # Custom variable values
├── variables.tf                # Input variable definitions
├── scripts/
│   └── bootstrap.ps1           # EC2 Windows init script


#Jenkins Pipeline Steps
1.Checkout Code
.2Terraform Init
3.Format & Validate
4.Terraform Plan
5.Apply with approval

#Jenkinsfile-destroy
1.Checkout Code
.2Terraform Init
3.'Terraform Plan Destroy
4.terraform destroy


#Test IIS Setup (via SSM)
# On EC2 via Session Manager
Get-Service W3SVC
Get-Website
Get-Content "C:\inetpub\wwwroot\index.html"
