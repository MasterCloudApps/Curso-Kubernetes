# Selecciona la imagen base
FROM openjdk:8-jre-slim

# Copia de la aplicación compilada
COPY target/*.jar /app/

# Define el directorio de trabajo para el comando
WORKDIR /app

# Indica el puerto que expone el contenedor
EXPOSE 8080

# Comando que se ejecuta al hacer docker run
CMD [ "java", "-jar", "java-webapp-0.0.1.jar" ]