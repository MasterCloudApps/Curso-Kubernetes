# Selecciona la imagen base
FROM alpine:3.5

# Instala python y pip
RUN apk add --update py-pip
RUN pip install --upgrade pip

# Copia el fichero de librerías
COPY requirements.txt /usr/src/app/

# Instala las librerías python que necesita la app
RUN pip install --no-cache-dir -r /usr/src/app/requirements.txt

# Copia el resto de ficheros de la aplicación
COPY app.py /usr/src/app/
COPY templates/index.html /usr/src/app/templates/

# Indica el puerto que expone el contenedor
EXPOSE 5000

# Comando que se ejecuta cuando se arranque el contenedor
CMD ["python", "/app/app.py"]
