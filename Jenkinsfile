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
        stage('Build & Push Docker image') {
            agent { label 'docker-enabled' }          // node must have Docker CLI & access
        environment {
        FULL_NAME = "${REGISTRY_URL}/${REGISTRY_REPO}/${IMAGE_NAME}"
    }
           steps {
        /* ----------------------------------------------------------
         * 1. Pick up the fresh JAR that Maven just produced
         *    – ignores *-original or *-javadoc jars
         * ---------------------------------------------------------- */
                  sh '''
                    echo "Listing jars in target/ ==="
                     ls -l target/*.jar || true

                     # Use newest non-*original.jar
                     JAR=$(ls -t target/*.jar | grep -v original | head -n1)
                     echo "Copying $JAR → app.jar"
                     cp "$JAR" app.jar
                 '''

        /* ----------------------------------------------------------
         * 2. Build & push the image
         * ---------------------------------------------------------- */
        script {
            docker.withRegistry("http://${REGISTRY_URL}", REGISTRY_CREDENTIAL) {
                def image = docker.build(
                    "${FULL_NAME}:${IMAGE_TAG}",
                    "--build-arg JAR_FILE=app.jar ."
                )
                image.push()
                image.push('latest')          // optional: tag as latest
            }
        }
    }

    /* --------------------------------------------------------------
     * 3. Always clean up local images so subsequent builds don’t run
     *    out of disk space – ignore failure if daemon is inaccessible
     * -------------------------------------------------------------- */
    post {
        always {
            sh """
                docker rmi ${FULL_NAME}:${IMAGE_TAG}  || true
                docker rmi ${FULL_NAME}:latest        || true
            """
        }
    }
}


    /* ---------- pipeline-level notifications ---------- */
    post {
        success { echo 'Pipeline completed successfully!' }
        failure { echo 'Pipeline failed!' }
    }
}   // ← final brace closes pipeline

