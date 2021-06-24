# Selecciona la imagen base
FROM python:3.9.5-alpine3.13

# Definimos el directorio de trabajo en /usr/src/app/
WORKDIR /usr/src/app/

# Copia el fichero de librerías
COPY requirements.txt /usr/src/app/

# Instala las librerías python que necesita la app
RUN pip install --no-cache-dir -r requirements.txt

# Copiamos los ficheros de la aplicación
COPY app.py /usr/src/app/
COPY templates /usr/src/app/templates

# Indica el puerto que expone el contenedor
EXPOSE 5000

# Comando que se ejecuta cuando se arranque el contenedor
CMD ["python", "app.py"]