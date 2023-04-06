FROM maven:3.9.0-eclipse-temurin-17 as builder
WORKDIR /project
COPY pom.xml /project/
COPY src /project/src
RUN mvn package -DskipTests

FROM eclipse-temurin:17-jdk
COPY --from=builder /project/target/*.jar /usr/src/app/
WORKDIR /usr/src/app/
EXPOSE 8080
CMD [ "java", "-jar", "demoservice1-k8s-0.0.1-SNAPSHOT.jar" ]