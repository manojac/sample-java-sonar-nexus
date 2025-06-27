# ./Dockerfile
FROM eclipse-temurin:17-jre
ARG JAR_FILE=app.jar
COPY ${JAR_FILE} /app.jar
ENTRYPOINT ["java","-jar","/app.jar"]
