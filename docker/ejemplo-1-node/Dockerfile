# Selecciona la imagen base
FROM node:lts-alpine

# Especificamos esta variable para la correcta ejecución de las librerías en modo de producción
ENV NODE_ENV production

# Definimos el directorio de trabajo en /usr/src/app/
WORKDIR /usr/src/app/

# Copiamos los ficheros de la aplicación
COPY src /usr/src/app/src
COPY package.json /usr/src/app/

# Instalamos las dependencias que necesita la app
RUN npm install --only=production

# Indica el puerto que expone el contenedor
EXPOSE 5000

# Comando que se ejecuta cuando se arranque el contenedor
CMD ["node", "src/server.js"]