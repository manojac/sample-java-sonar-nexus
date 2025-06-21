pipeline {
    agent any

    environment {
        // Used by SonarQube plugin block
        SONAR_HOST_URL = 'http://52.66.69.172:30900'
    }

    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/akash-devops2/sample-java-sonar-nexus.git', branch: 'main'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withCredentials([string(credentialsId: 'sonar-token-id', variable: 'SONAR_TOKEN')]) {
                    withSonarQubeEnv('MySonar') {
                        sh '''
                            mvn clean verify sonar:sonar \
                              -Dsonar.projectKey=sample-java-app \
                              -Dsonar.host.url=$SONAR_HOST_URL \
                              -Dsonar.login=$SONAR_TOKEN
                        '''
                    }
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
                echo "Upload to Nexus would happen here (plugin or curl-based depending on Nexus setup)."
                // You can add Nexus upload logic if needed.
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully!'
        }
        failu
