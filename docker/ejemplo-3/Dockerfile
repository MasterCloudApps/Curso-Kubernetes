#################################################
# Imagen base para el contenedor de compilación
#################################################
FROM maven:3.6.3-openjdk-8 as builder

# Define el directorio de trabajo donde ejecutar comandos
WORKDIR /project

# Copia las dependencias del proyecto
COPY pom.xml /project/

# Descarga las dependencias del proyecto
RUN mvn clean verify

# Copia el código del proyecto
COPY /src /project/src

# Compila proyecto
RUN mvn package -o

#################################################
# Imagen base para el contenedor de la aplicación
#################################################
FROM openjdk:8-jre-slim

# Define el directorio de trabajo donde se encuentra el JAR
WORKDIR /usr/src/app/

# Copia el JAR del contenedor de compilación
COPY --from=builder /project/target/app-jar-with-dependencies.jar /usr/src/app/

# Indica el puerto que expone el contenedor
EXPOSE 8080

# Comando por defecto
ENTRYPOINT [ "java", "-jar", "app-jar-with-dependencies.jar" ]

# Parametro por defecto
CMD ["--server"]