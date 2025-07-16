### Project: terraform-cicd
##Purpose:
This repository provides the CI/CD pipeline automation for your Terraform-based AWS infrastructure. It integrates with Jenkins, manages secure credential injection, runs Terraform provisioning, and enables full infrastructure-as-code delivery and destruction workflows.

It serves as the automation controller for your terraform-CloudOps infrastructure definitions.

###Repository Structure

terraform-cicd/
├── Jenkinsfile
├── Jenkinsfile-destroy
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
├── .terraform/
├── .terraform.lock.hcl
├── .gitignore
├── scripts/
│   └── bootstrap.ps1
├── README.md
└── README.txt


###File Overview & Purpose
##Jenkinsfile
Main CI/CD pipeline for Terraform Apply:

Stages:

1.Checkout SCM

2.Terraform Init

3.Terraform Format & Validate

4.Terraform Plan

5.Terraform Apply (with input approval)

###Injects secrets from Jenkins:

environment {
  AWS_ACCESS_KEY_ID     = credentials('aws-access-key')
  AWS_SECRET_ACCESS_KEY = credentials('aws-secret-key')
  TF_VAR_db_user        = credentials('db-user')
  TF_VAR_db_pass        = credentials('db-pass')
}
##Fully automated, interactive apply.##

##Jenkinsfile-destroy
Reversible pipeline to destroy infrastructure using:
terraform destroy -auto-approve



Reuses the same credentials and state as the apply pipeline.

### main.tf
Minimal Terraform configuration to support backend or pipeline validation (optional for pipeline-only repos).

Currently unused since the actual infra is defined in terraform-cloudops.

##variables.tf / terraform.tfvars
Optionally define reusable variables and their values.

Not mandatory, since values are passed via Jenkins environment injection.

## README.md & README.txt
Meant for human-readable documentation.
Can include:
CI/CD flow
Credential ID references
Deployment instructions
Secrets injection diagram

###Design Rationale
Element	Rationale
Pipeline split	Separate apply and destroy jobs prevent accidental deletion.
Credential Injection	Sensitive AWS & DB credentials securely passed via Jenkins secrets.
Jenkinsfile in Git	Enables GitOps — Jenkins pulls pipeline config directly from the repo.
Terraform Plan gating	Human approval gate adds safety before provisioning.
.tfvars file	Supports local testing and manual CLI runs if needed.

###Credentials in Jenkins
ID	Type	Description
aws-access-key	String / AWS creds	AWS Access Key
aws-secret-key	String / AWS creds	AWS Secret Key
db-user	Plain String	RDS Username
db-pass	Plain String	RDS Password

###These are used in both Jenkinsfile and Jenkinsfile-destroy.
##CI/CD Flow (Summary)
Push changes to GitHub

#Jenkins auto-triggers job (or manual start)
Jenkins:
Clones the repo
Sets credentials
Runs terraform init, fmt, validate, plan
Requests manual confirmation
Applies infra on approval

#Reverse process via Jenkinsfile-destroy
