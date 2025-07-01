pipeline {
    agent any

    environment {
        JAVA_HOME = "/usr/lib/jvm/java-21-amazon-corretto.x86_64"
        PATH = "${JAVA_HOME}/bin:${env.PATH}"
        GIT_REPO_URL = 'https://github.com/manojac/sample-java-sonar-nexus.git'
        SONAR_URL = 'http://3.111.214.55:30900'
        SONAR_TOKEN = 'squ_b32ed949b7fcc7d845ae15bac7687934c92c6bdd'
        SONAR_CRED_ID = 'my-sonar'
        MAX_BUILDS_TO_KEEP = 5
        NEXUS_URL = 'http://3.111.214.55:30801'
        NEXUS_DOCKER_REPO = '3.111.214.55:30002' // Updated to correct HTTP port
        NEXUS_CREDENTIAL_ID = 'nexus-creds'
    }

    tools {
        maven 'maven-3.9.10'
    }

    stages {
        stage('Checkout') {
            steps {
                git url: "${GIT_REPO_URL}", branch: 'main'
            }
        }

        stage('Create Sonar Project') {
            steps {
                script {
                    def projectName = "${env.JOB_NAME}-${env.BUILD_NUMBER}".replace('/', '-')
                    withCredentials([usernamePassword(credentialsId: "${SONAR_CRED_ID}", usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                        sh """
                        curl -s -o /dev/null -w "%{http_code}" -u $USERNAME:$PASSWORD -X POST \
                          "${SONAR_URL}/api/projects/create?project=${projectName}&name=${projectName}" || true
                        """
                    }
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    def projectName = "${env.JOB_NAME}-${env.BUILD_NUMBER}".replace('/', '-')
                    sh """
                    mvn clean verify sonar:sonar \
                      -Dsonar.projectKey=${projectName} \
                      -Dsonar.host.url=${SONAR_URL} \
                      -Dsonar.login=${SONAR_TOKEN}
                    """
                }
            }
        }

        stage('Build and Tag Artifact') {
            steps {
                script {
                    sh "mvn clean package -DskipTests"
                    def artifactName = "my-app-${BUILD_NUMBER}.jar"
                    sh """
                        mkdir -p tagged-artifacts
                        cp target/*.jar tagged-artifacts/${artifactName}
                        echo "Artifact tagged as ${artifactName}"
                    """
                }
            }
        }

        stage('Push Artifact to Nexus') {
            steps {
                script {
                    def version = "1.0.${BUILD_NUMBER}"
                    def artifactId = "my-app"
                    def groupPath = "com/mycompany/app"
                    def nexusPath = "${groupPath}/${artifactId}/${version}"
                    def finalArtifact = "${artifactId}-${version}.jar"

                    sh """
                        mv tagged-artifacts/my-app-${BUILD_NUMBER}.jar tagged-artifacts/${finalArtifact}
                    """

                    withCredentials([usernamePassword(credentialsId: "${NEXUS_CREDENTIAL_ID}", usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
                        sh """
                        curl -u $NEXUS_USER:$NEXUS_PASS \
                             --upload-file tagged-artifacts/${finalArtifact} \
                             ${NEXUS_URL}${nexusPath}/${finalArtifact}
                        """
                    }
                }
            }
        }

        stage('Create Dockerfile') {
            steps {
                script {
                    writeFile file: 'Dockerfile', text: """
                    FROM openjdk:21-jdk-slim
                    WORKDIR /app
                    COPY tagged-artifacts/my-app-*.jar app.jar
                    EXPOSE 8080
                    ENTRYPOINT ["java", "-jar", "app.jar"]
                    """
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def imageTag = "${NEXUS_DOCKER_REPO}/my-app:${BUILD_NUMBER}"
                    sh "docker build -t ${imageTag} ."
                }
            }
        }

        stage('Push Docker Image to Nexus') {
            steps {
                script {
                    def imageTag = "${NEXUS_DOCKER_REPO}/my-app:${BUILD_NUMBER}"
                    withCredentials([usernamePassword(credentialsId: "${NEXUS_CREDENTIAL_ID}", usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
                        sh """
                            echo $NEXUS_PASS | docker login http://${NEXUS_DOCKER_REPO} -u $NEXUS_USER --password-stdin
                            docker push ${imageTag}
                            docker logout http://${NEXUS_DOCKER_REPO}
                        """
                    }
                }
            }
        }

        stage('Delete Old Sonar Projects') {
            steps {
                script {
                    def currentBuild = env.BUILD_NUMBER.toInteger()
                    def minBuildToKeep = currentBuild - MAX_BUILDS_TO_KEEP.toInteger()

                    if (minBuildToKeep > 0) {
                        withCredentials([usernamePassword(credentialsId: "${SONAR_CRED_ID}", usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                            for (int i = 1; i <= minBuildToKeep; i++) {
                                def oldProject = "${env.JOB_NAME}-${i}".replace('/', '-')
                                echo "Deleting old Sonar project: ${oldProject}"
                                sh """
                                curl -s -o /dev/null -w "%{http_code}" -u $USERNAME:$PASSWORD -X POST \
                                  "${SONAR_URL}/api/projects/delete" \
                                  -d "project=${oldProject}" || true
                                """
                            }
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}

