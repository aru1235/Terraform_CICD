pipeline {
  agent any
  
  stages {
    stage("test AWS credentials") {
            steps {
                withCredentials([<object of type com.cloudbees.jenkins.plugins.awscredentials.AmazonWebServicesCredentialsBinding>]) {
    // some block
}
            }
    }
    stage("test git credentials") {
            steps {
               withCredentials([gitUsernamePassword(credentialsId: 'my-git-id', gitToolName: 'git-tool')]) {
                 sh 'git fetch --all'
           }
       }
    }
    
    stage("Clone Terraform code") {
      steps {
        git "https://github.com/aru1235/Terraform_CICD.git"
      }
    }
    
    stage("Terraform Init") {
      steps {
        sh "terraform init"
      }
    }
    
    stage("Terraform Plan") {
      steps {
        sh "terraform plan -out=tfplan"
      }
    }
    
    stage("Terraform Apply") {
      steps {
        sh "terraform apply tfplan"
      }
      post {
        success {
          echo "Terraform apply was successful"
        }
        failure {
          echo "Terraform apply failed"
        }
      }
    }
  }
}
