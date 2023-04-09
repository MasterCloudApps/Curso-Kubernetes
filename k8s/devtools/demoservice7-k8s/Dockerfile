
FROM maven:3.9.0-eclipse-temurin-17 as builder
WORKDIR /project
COPY pom.xml /project/
RUN mvn -B clean verify
COPY /src /project/src
RUN mvn -B -o package -DskipTests

FROM eclipse-temurin:17-jdk
WORKDIR /usr/src/app/
RUN curl -LJO https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh \
    && chmod +x /usr/src/app/wait-for-it.sh
COPY --from=builder /project/target/*.jar /usr/src/app/
EXPOSE 8080
CMD [ "sh", "-c", "./wait-for-it.sh -s -t 30 ${DATABASE_HOST:-localhost}:${DATABASE_PORT:-3306} -- java -jar demoservice7-k8s-0.0.1-SNAPSHOT.jar" ]