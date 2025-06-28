pipeline {
    agent any

    environment {
        SONAR_HOST_URL          = 'http://13.233.237.182:30900'
        NEXUS_URL               = 'http://13.233.237.182:30801'
        NEXUS_REPO              = 'maven-releases'
        GROUP_ID                = 'com.devops'
        ARTIFACT_ID             = 'sample-java-app' 
        VERSION                 = "1.${BUILD_NUMBER}"
        FILE_NAME               = "sample-java-app-${VERSION}.jar"
        DOCKER_IMAGE_NAME       = 'sample-java-app'
        NEXUS_DOCKER_REGISTRY   = '13.233.237.182:8082'
    }

    stages {
        stage('Build') {
            steps {
                sh "mvn versions:set -DnewVersion=${VERSION}"
                sh 'mvn clean package'
                sh 'ls -l target/'
                sh "echo \"📦 Built JAR: target/sample-java-app-${VERSION}.jar\""
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withCredentials([string(credentialsId: 'sonar-token-id', variable: 'SONAR_TOKEN')]) {
                    withSonarQubeEnv('MySonar') {
                        sh """
                            mvn clean verify sonar:sonar \
                            -Dsonar.projectKey=sample-java-app \
                            -Dsonar.projectVersion=${VERSION} \
                            -Dsonar.host.url=${SONAR_HOST_URL} \
                            -Dsonar.login=${SONAR_TOKEN}
                        """
                    }
                }
            }
        }

        stage('Upload to Nexus Maven Repo') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'nexus-creds', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    script {
                        def groupPath = GROUP_ID.replace('.', '/')
                        def uploadUrl = "${NEXUS_URL}/repository/${NEXUS_REPO}/${groupPath}/${ARTIFACT_ID}/${VERSION}/${FILE_NAME}"

                        sh """
                            curl -v -u $USERNAME:$PASSWORD --upload-file target/${FILE_NAME} ${uploadUrl}
                        """
                    }
                }
            }
        }

        stage('Download .jar from Nexus') {
            steps {
                sh 'mkdir -p downloaded-artifact'
                withCredentials([usernamePassword(credentialsId: 'nexus-creds', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    script {
                        def groupPath = GROUP_ID.replace('.', '/')
                        def downloadUrl = "${NEXUS_URL}/repository/${NEXUS_REPO}/${groupPath}/${ARTIFACT_ID}/${VERSION}/${FILE_NAME}"

                        sh """
                            cd downloaded-artifact
                            curl -u $USERNAME:$PASSWORD -O ${downloadUrl}
                            ls -l
                        """
                    }
                }
            }
        }

        stage('Build & Push Docker Image to Nexus Docker Registry') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'nexus-docker-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    script {
                        def imageTag = "${NEXUS_DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:${VERSION}"

                        writeFile file: 'Dockerfile', text: """
                        FROM openjdk:17
                        WORKDIR /app
                        COPY downloaded-artifact/${FILE_NAME} app.jar
                        ENTRYPOINT ["java", "-jar", "app.jar"]
                        """

                        sh """
                            docker build -t ${imageTag} .
                            echo "$DOCKER_PASS" | docker login ${NEXUS_DOCKER_REGISTRY} -u "$DOCKER_USER" --password-stdin
                            docker push ${imageTag}
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline completed successfully!'
        }
        failure {
            echo '❌ Pipeline failed!'
        }
    }
}
