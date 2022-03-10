# Selecciona la imagen base
FROM maven:3.8.4-openjdk-17

# Define el directorio de trabajo donde ejecutar comandos
WORKDIR /project

# Copia el código del proyecto
COPY aplicacion-java-enunciado/ /project/

# Compila proyecto y descarga librerías
RUN mvn -B package

# Indica el puerto que expone el contenedor
EXPOSE 8080

# Comando que se ejecuta al hacer docker run
CMD ["java", "-jar", "target/java-webapp-0.0.1.jar"]
