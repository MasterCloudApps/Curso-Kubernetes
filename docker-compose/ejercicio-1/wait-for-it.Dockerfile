#################################################
# Imagen base para el contenedor de compilación
#################################################
FROM maven:3.6.3-openjdk-8 as builder

# Copia el código del proyecto
COPY /src /project/src
COPY pom.xml /project/

# Define el directorio de trabajo donde ejecutar comandos
WORKDIR /project

# Compila proyecto y descarga librerías
RUN mvn package -DskipTests=true

#################################################
# Imagen base para el contenedor de la aplicación
#################################################
FROM openjdk:8-jre-slim

# Descargamos el script wait-for-it.sh
ADD https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh /usr/app/
RUN chmod +x /usr/app/wait-for-it.sh

# Copia el JAR del contenedor de compilación
COPY --from=builder /project/target/*.jar /usr/app/

# Define el directorio de trabajo donde se encuentra el JAR
WORKDIR /usr/app

# Indica el puerto que expone el contenedor
EXPOSE 8080

# Comando que se ejecuta al hacer docker run
CMD [ "java", "-jar", "app.jar" ]