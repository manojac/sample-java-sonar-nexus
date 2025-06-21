pipeline {
  agent any

  environment {
    SONARQUBE = 'MySonar'                           // Matches Jenkins SonarQube Server config name
  }

  stages {
    stage('Checkout') {
      steps {
        git branch: 'main', url: 'https://github.com/akash-devops2/sample-java-sonar-nexus.git'
      }
    }

    stage('SonarQube Analysis') {
      environment {
        SONAR_TOKEN = credentials('sonar-token-id')  // Inject inside stage to keep scope limited
      }
      steps {
        withSonarQubeEnv("${SONARQUBE}") {
          sh '''
            mvn clean verify sonar:sonar \
              -Dsonar.projectKey=sample-java-app \
              -Dsonar.host.url=http://52.66.69.172:30900 \
              -Dsonar.login=$SONAR_TOKEN
          '''
        }
      }
    }

    stage('Build') {
      steps {
        sh 'mvn package'
      }
    }

    stage('Upload to Nexus') {
      environment {
        NEXUS_CRED = credentials('nexus-cred-id')
      }
      steps {
        nexusArtifactUploader(
          nexusVersion: 'nexus3',
          protocol: 'http',
          nexusUrl: '52.66.69.172:30801',
          groupId: 'com.devops',
          artifactId: 'sample-java-app',
          version: '1.0',
          repository: 'maven-releases',
          credentialsId: 'nexus-cred-id',
          artifacts: [[
            artifactId: 'sample-java-app',
            classifier: '',
            file: 'target/sample-java-app-1.0.jar',
            type: 'jar'
          ]]
        )
      }
    }
  }
}
