FROM maven as builder
WORKDIR /code
COPY pom.xml pom.xml
COPY src src
RUN mvn -DskipTests=true package

FROM openjdk:8-jre
COPY --from=builder /code/target/*.jar /app/
WORKDIR /app
COPY scripts/wait-for-it.sh wait-for-it.sh
RUN chmod +x wait-for-it.sh
COPY scripts/run.sh run.sh
RUN chmod +x run.sh
EXPOSE 8080
CMD ["./run.sh"]
