#################################################
# Imagen base para el contenedor de compilación
#################################################
FROM node:lts-alpine as builder

# Definimos el directorio de trabajo en /usr/src/app/
WORKDIR /usr/src/app/

# Copiamos fichero de dependencias
COPY package.json /usr/src/app/

# Instalamos las dependencias que necesita la app
RUN npm install --only=production

#################################################
# Imagen base para el contenedor de la aplicación
#################################################
FROM node:lts-alpine

# Especificamos esta variable para la correcta ejecución de las librerías en modo de producción
ENV NODE_ENV production

# Definimos el directorio de trabajo en /usr/src/app/
WORKDIR /usr/src/app

# Copiamos el node_modules con todas las dependencias instaladas de la imagen de compilación
COPY --from=builder /usr/src/app/node_modules /usr/src/app/node_modules

# Copiamos los ficheros de la aplicación
COPY src /usr/src/app/src

# Indica el puerto que expone el contenedor
EXPOSE 5000

# Comando que se ejecuta cuando se arranque el contenedor
CMD ["node", "src/server.js"]
