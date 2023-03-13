#!/bin/bash

# Leer el nombre de la imagen
IMAGE_NAME=${1:-miusuario/ejer8:v1}

# Crear imagen docker
mvn -Pnative spring-boot:build-image -Dspring-boot.build-image.imageName="$IMAGE_NAME"