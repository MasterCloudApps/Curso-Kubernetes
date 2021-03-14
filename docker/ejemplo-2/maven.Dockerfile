# Selecciona la imagen base
FROM maven:3.6.3-openjdk-8

# Define el directorio de trabajo donde ejecutar comandos
WORKDIR /project

# Copia el código del proyecto
COPY /src /project/src
COPY pom.xml /project/

# Compila proyecto y descarga librerías
RUN mvn package

# Indica el puerto que expone el contenedor
EXPOSE 8080

# Comando que se ejecuta al hacer docker run
CMD ["java", "-jar", "target/java-webapp-0.0.1.jar"]