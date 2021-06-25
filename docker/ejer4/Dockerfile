FROM maven:3-openjdk-11

COPY aplicacion-java-enunciado/ /project/

WORKDIR /project

RUN mvn package

EXPOSE 8080

CMD ["java", "-jar", "target/java-webapp-0.0.1.jar"]
