# Dockerfile.jenkins-agent
FROM jenkins/inbound-agent:latest

USER root

ARG HOST_DOCKER_GID

# Install Docker CLI dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      apt-transport-https ca-certificates curl gnupg2 software-properties-common && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - && \
    echo "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
        > /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends docker-ce-cli && \
    rm -rf /var/lib/apt/lists/*

# Create docker group matching the host and add jenkins user to it
RUN groupadd -g ${HOST_DOCKER_GID} docker && \
    usermod -aG docker jenkins

USER jenkins

