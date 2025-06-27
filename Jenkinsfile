pipeline {
    agent any

    environment {
        SONAR_HOST_URL = 'http://13.233.237.182:30900'
        NEXUS_URL = 'http://13.233.237.182:30801'  // Replace with your actual Nexus URL
        REPO = 'maven-releases'
        GROUP_ID = 'com.devops'
        ARTIFACT_ID = 'sample-java-app'
        VERSION = '1.0'
        PACKAGING = 'jar'
        FILE = 'target/sample-java-app-1.0.jar'
    }

    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/manojac/sample-java-sonar-nexus.git', branch: 'main'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                    withSonarQubeEnv('MySonar') {
                        sh '''
                            mvn clean verify sonar:sonar \
                              -Dsonar.projectKey=sample-java-app \
                              -Dsonar.host.url=$SONAR_HOST_URL \
                              -Dsonar.login=$SONAR_TOKEN \
                              -Dsonar.verbose=true
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
                withCredentials([usernamePassword(credentialsId: 'nexus-creds', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    sh '''
                        curl -v -u $USERNAME:$PASSWORD --upload-file $FILE \
                        $NEXUS_URL/repository/$REPO/$(echo $GROUP_ID | tr '.' '/')/$ARTIFACT_ID/$VERSION/$ARTIFACT_ID-$VERSION.$PACKAGING
                    '''
    environment { 
        REGISTRY_URL        = 'http://13.233.237.182:8083'      // 🔄 change me
        IMAGE_NAME          = '13.233.237.182:8083/docker-hosted/my-app:1.0'             // 🔄 change me
        REGISTRY_CREDENTIAL = 'nexus-docker-creds'          // 🔄 credential ID
        IMAGE_TAG           = "${env.BUILD_NUMBER}"         // build-specific tag
    }

    
        /* …your existing Build + Upload to Nexus stages… */

        stage('Build & Push Docker image') {
            steps {
                script {
                    // ❶ Make sure the jar is where the Dockerfile can see it
                    sh 'cp target/sample-java-app.jar app.jar'

                    // ❷ Build the image (and hand the jar path via build-arg)
                    docker.withRegistry("https://${REGISTRY_URL}",
                                        REGISTRY_CREDENTIAL) {
                        def image = docker.build(
                            "${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG}",
                            "--build-arg JAR_FILE=app.jar ."
                        )

                        // ❸ Push versioned tag
                        image.push()

                        // ❹ Update / push the floating "latest" tag
                        image.push('latest')
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
