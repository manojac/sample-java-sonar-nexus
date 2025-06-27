pipeline {
    /* ---------- where the build runs ---------- */
    agent any                   // or:  agent { label 'docker-enabled' }

    /* ---------- global variables ---------- */
    environment {
        /* Sonar & Maven-artifact settings */
        SONAR_HOST_URL = 'http://13.233.237.182:30900'
        NEXUS_URL      = 'http://13.233.237.182:30801'    // 🔄 Nexus host:port (Maven repo)
        REPO           = 'maven-releases'
        GROUP_ID       = 'com.devops'
        ARTIFACT_ID    = 'sample-java-app'
        VERSION        = '1.0'
        PACKAGING      = 'jar'
        FILE           = 'target/sample-java-app-1.0.jar'

        /* Docker / container registry settings */
        REGISTRY_URL        = '13.233.237.182:8083'       // 🔄 Nexus Docker repo host:port
        REGISTRY_REPO       = 'docker-hosted'             // 🔄 Nexus *Docker*-type repo name
        IMAGE_NAME          = 'my-app'                    // 🔄 image repo/name (no tag)
        REGISTRY_CREDENTIAL = 'nexus-docker-creds'        // 🔄 Jenkins cred ID (user/pass)
        IMAGE_TAG           = "${env.BUILD_NUMBER}"       // pipeline build number
    }

    /* ---------- pipeline flow ---------- */
    stages {
        
        stage('Who am I?') {
            steps {
                sh '''
                    echo "=== identity ==="
                    id -un
                    id -Gn
                    echo "=== socket perms ==="
                    ls -l /var/run/docker.sock || true
                '''
            }
        }

        stage('Checkout') {
            steps {
                sh 'echo "I am $(id -un) with groups: $(id -Gn)"'
               git url: 'https://github.com/manojac/sample-java-sonar-nexus.git',
                    branch: 'main'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withCredentials([string(credentialsId: 'sonar-token',
                                        variable: 'SONAR_TOKEN')]) {
                    withSonarQubeEnv('MySonar') {
                        sh '''
                          mvn -B clean verify sonar:sonar \
                            -Dsonar.projectKey=sample-java-app \
                            -Dsonar.host.url=$SONAR_HOST_URL \
                            -Dsonar.login=$SONAR_TOKEN \
                            -Dsonar.verbose=true
                        '''
                    }
                }
            }
        }

        stage('Build JAR') {
            steps {
                sh 'mvn -B package'
            }
        }

        stage('Upload JAR to Nexus') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'nexus-creds',
                                                  usernameVariable: 'USERNAME',
                                                  passwordVariable: 'PASSWORD')]) {
                    sh '''
                      curl -v -u $USERNAME:$PASSWORD --upload-file $FILE \
                      $NEXUS_URL/repository/$REPO/$(echo $GROUP_ID | tr '.' '/')/$ARTIFACT_ID/$VERSION/$ARTIFACT_ID-$VERSION.$PACKAGING
                    '''
                }
            }
        }

        /* --------------------------------------------- */
        /* build, tag and push Docker image to Nexus     */
        /* --------------------------------------------- */
        stage('Build & Push Docker image') {
            agent { label 'docker-enabled' }   // node must have Docker daemon/CLI
            steps {
                sh '''
                   echo "Looking for jar in target/..."
                   ls -lh target/

                  JAR=$(ls -t target/*.jar | grep -v original | head -n1)
                  echo "Copying $JAR → app.jar"
                  cp "$JAR" app.jar
                '''

                script {
                    /* login, build and push */
                    docker.withRegistry("http://${REGISTRY_URL}", REGISTRY_CREDENTIAL) {

                        def fullName = "${REGISTRY_URL}/${REGISTRY_REPO}/${IMAGE_NAME}"
                        def image = docker.build(
                            "${fullName}:${IMAGE_TAG}",
                            "--build-arg JAR_FILE=app.jar ."
                        )

                        image.push()         // versioned tag
                        image.push('latest') // floating tag
                    }
                }
            }
            post {
                always {
                    /* keep agents clean */
                    sh '''
                      docker rmi ${REGISTRY_URL}/${REGISTRY_REPO}/${IMAGE_NAME}:${IMAGE_TAG} || true
                      docker rmi ${REGISTRY_URL}/${REGISTRY_REPO}/${IMAGE_NAME}:latest || true
                      docker rmi $IMAGE || true
                    '''
                }
            }
        }
    }  // ← closes stages

    /* ---------- pipeline-level notifications ---------- */
    post {
        success { echo 'Pipeline completed successfully!' }
        failure { echo 'Pipeline failed!' }
    }
}   // ← final brace closes pipeline

