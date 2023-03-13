#!/bin/bash

# Leer el nombre de la imagen
IMAGE_NAME=${1:-miusuario/ejer7:v1}

# Crear imagen docker
mvn spring-boot:build-image -Dspring-boot.build-image.imageName="$IMAGE_NAME"