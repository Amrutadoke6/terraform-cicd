pipeline {
  agent any

  environment {
    AWS_ACCESS_KEY_ID     = credentials('aws-access-key')
    AWS_SECRET_ACCESS_KEY = credentials('aws-secret-key')
    TF_VAR_db_user        = credentials('db_user')      
    TF_VAR_db_pass        = credentials('db_pass')      
    TF_VAR_region         = 'us-east-2'
  }

  stages {
    stage('Checkout Code') {
      steps {
        git branch: 'main', url: 'https://github.com/Amrutadoke6/terraform-cicd.git'
      }
    }

    stage('Terraform Init') {
      steps {
        sh 'terraform init'
      }
    }

    stage('Terraform Format & Validate') {
      steps {
        sh 'terraform fmt -check'
        sh 'terraform validate'
      }
    }

    stage('Terraform Plan') {
      steps {
        sh 'terraform plan -out=tfplan'
      }
    }

    stage('Terraform Apply') {
      steps {
        input message: "Apply Terraform changes?"
        sh 'terraform apply tfplan'
      }
    }
  }

  post {
    failure {
      echo "Terraform CICD pipeline failed "
    }
    success {
      echo "Terraform infrastructure created successfully "
    }
  }
}

