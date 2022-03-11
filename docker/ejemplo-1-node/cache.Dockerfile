# Selecciona la imagen base
FROM node:lts-alpine

# Especificamos esta variable para la correcta ejecución de las librerías en modo de producción
ENV NODE_ENV production

# Definimos el directorio de trabajo en /usr/src/app/
WORKDIR /usr/src/app/

# Copiamos fichero de dependencias
COPY package.json /usr/src/app/

# Instalamos las dependencias que necesita la app
RUN npm install --only=production

# Copiamos el resto de ficheros de la aplicación
COPY server.js /usr/src/app/
COPY views/index.html /usr/src/app/views/

# Indica el puerto que expone el contenedor
EXPOSE 5000

# Comando que se ejecuta cuando se arranque el contenedor
CMD ["node", "src/server.js"]