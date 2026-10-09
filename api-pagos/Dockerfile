# 1. Se utiliza una imagen base oficial, ligera y segura.
FROM node:20-alpine

# 2. Definimos que estamos en el ambiente de producción.
ENV NODE_ENV=production

# 3. Establecemos el directorio de trabajo dentro del contenedor.
WORKDIR /usr/src/app

# 4. Modificamos el dueño de la carpeta para que el usuario sin privilegios pueda usarla.
RUN chown -R node:node /usr/src/app

# 5. Cambiamos al usuario sin privilegios para mejorar la seguridad.
USER node

# 6. Copiamos los archivos de dependencias primero para aprovechar el caché de docker.
COPY --chown=node:node package*.json ./

# 7. Instalamos las dependencias en modo limpio y solo de producción.
RUN npm ci --only=production

# 8. Copiamos el resto de la aplicación al contenedor.
COPY --chown=node:node src/ ./src/

# 9. Exponemos el puerto en el que escuchará la aplicación por defecto.
EXPOSE 8080

# 10. Comando para levantar la aplicación.
CMD ["npm", "start"]