pipeline {
  agent any

  environment {
    SONARQUBE = 'MySonar'
    SONAR_TOKEN = credentials('sonar-token-id')
    NEXUS_CRED = credentials('nexus-cred-id')
    NEXUS_URL = 'http://<your-ec2>:30801/repository/maven-releases/'
  }

  stages {
    stage('Checkout') {
      steps {
        git 'https://github.com/akash-devops2/sample-java-sonar-nexus.git'
      }
    }

    stage('SonarQube Analysis') {
      steps {
        withSonarQubeEnv("${SONARQUBE}") {
          sh 'mvn clean verify sonar:sonar -Dsonar.login=$SONAR_TOKEN'
        }
      }
    }

    stage('Build') {
      steps {
        sh 'mvn package'
      }
    }

    stage('Upload to Nexus') {
      steps {
        nexusArtifactUploader(
          nexusVersion: 'nexus3',
          protocol: 'http',
          nexusUrl: '3.110.42.224:30801',
          groupId: 'com.devops',
          version: '1.0',
          repository: 'maven-releases',
          credentialsId: 'nexus-cred-id',
          artifacts: [[artifactId: 'sample-java-app',
                       classifier: '',
                       file: 'target/sample-java-app.jar',
                       type: 'jar']]
        )
      }
    }
  }
}
