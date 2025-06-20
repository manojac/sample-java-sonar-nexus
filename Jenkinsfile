pipeline {
  agent any

  environment {
    SONARQUBE = 'MySonar'                          // Must match Jenkins SonarQube config
    SONAR_TOKEN = credentials('sonar-token-id')    // Jenkins secret text credential
    NEXUS_CRED = credentials('nexus-cred-id')      // Jenkins username/password credential
  }

  stages {
    stage('Checkout') {
      steps {
        git branch: 'main', url: 'https://github.com/akash-devops2/sample-java-sonar-nexus.git'
      }
    }

    stage('SonarQube Analysis') {
      steps {
        withSonarQubeEnv("${SONARQUBE}") {
          sh """
            mvn clean verify sonar:sonar \
              -Dsonar.projectKey=sample-java-app \
              -Dsonar.host.url=http://13.200.222.92:9000 \
              -Dsonar.login=${SONAR_TOKEN}
          """
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
          nexusUrl: '13.200.222.92:30801',
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
