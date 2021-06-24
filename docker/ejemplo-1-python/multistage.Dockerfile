#################################################
# Imagen base para el contenedor de compilación
#################################################
FROM python:3.9.5-alpine3.13 as builder

# Definimos el directorio de trabajo en /usr/src/app/
WORKDIR /usr/src/app/

# Copiamos fichero de dependencias
COPY requirements.txt /usr/src/app/

# Instalamos las dependencias que necesita la app
RUN pip install --user -r requirements.txt

#################################################
# Imagen base para el contenedor de la aplicación
#################################################
FROM python:3.9.5-alpine3.13

# Definimos el directorio de trabajo en /usr/src/app/
WORKDIR /usr/src/app

# Copiamos la carpeta con todas las dependencias instaladas de la imagen de compilación
COPY --from=builder /root/.local /root/.local

# Copiamos los ficheros de la aplicación
COPY app.py /usr/src/app/
COPY templates /usr/src/app/templates/

# Indica el puerto que expone el contenedor
EXPOSE 5000

# Comando que se ejecuta cuando se arranque el contenedor
CMD ["python", "app.py"]