pipeline {
  agent any
  
  stages {
    stage('Clone Terraform code') {
      steps {
        git 'https://github.com/aru1235/Terraform_demo'
      }
    }
    
    stage('Terraform Init') {
      steps {
        sh 'terraform init'
      }
    }
    
    stage('Terraform Plan') {
      steps {
        sh 'terraform plan -out=tfplan'
      }
    }
    
    stage('Terraform Apply') {
      steps {
        sh 'terraform apply tfplan'
      }
      post {
        success {
          echo 'Terraform apply was successful'
        }
        failure {
          echo 'Terraform apply failed'
        }
      }
    }
  }
}
