# Registro y Solución de Errores en la API de Pagos.
Se registran los erorres que se tuvieron a la hora de armar, y también correr los contenedores que contienen la API de pagos. Se documentan los errores y sus soluciones para futuras referencias.

## Errores. 
1. Error: "Error response from daemon: manifest for fededlv/api-pagos:1.0.0 not found: manifest unknown: manifest unknown"
------------------------------------------------------------------------------------------------------------------------
2. Error: "Step 6/10 : COPY --chown=node:node package*.json ./
  COPY failed: no source files were specified"
------------------------------------------------------------------------------------------------------------------------
3. Error: "{"error":"Error al crear el pago"}"

## Solución.
1. El primer error que se documenta hace referencia principalmente a la busqueda de la imagen api-pagos:1.0.0 en el repositorio de docker hub, y no se encuentra. Esto se debe a que la imagen no fue subida al repositorio de docker hub, si se desea que se busque la imagen subida a un repositorio de docker hub primero la imagen debe ser subida al repositorio de docker hub, pero también la otra alternativa para dar solución es construir la imagen de forma local. En este caso para la prueba individual de la API de pagos se construyó la imagen de forma local y se utilizó la imagen local para correr el contenedor de la API de pagos.
    El comando utilizado para construir la imagen de forma local es el siguiente:
    `docker build -t fededlv/api-pagos:1.0.0 -f api-pagos/Dockerfile .`
------------------------------------------------------------------------------------------------------------------------
2. El segundo error que se documenta es sobre el Build Context, esto se dio principalmente por estar parado en la raiz del proyecto cuando se ejecutó el comando build para construir la imagen de la API de pagos, y no en la carpeta api-pagos ¿Por qué se necesita estar parado en la carpeta correspondiente? Porque el "." del final del comando indica el Build Context, es decir, le indica a Docker "Toma todos los archivos de la carpeta en la que estoy parado ahora mismo (la raíz del proyecto) y úsalos como tu universo para construir", luego de esto Docker buscaba en la raiz del proyecto los archivos `package*.json` y no los encontraba porque estos archivos se encuentran alojados en la carpeta propia del servicio api-pagos. La solución a este error es pararse en la carpeta api-pagos y ejecutar el comando build para construir la imagen de la API de pagos.
   Con el siguiente comando:
   `docker build -t fededlv/api-pagos:1.0.0 .`
------------------------------------------------------------------------------------------------------------------------
3. El error que se documenta hace referencia a un error que se dio al momento de probar crear un pago, es decir que la API no pudo guardar el registro en la base de datos. Lo que causo este error, fue que se configuró de forma incorrecta el puerto dentro del archivo .env de la API, colocando el puerto que escucha el host y no el puerto que escucha el contenedor de la base de datos, por lo que la API no pudo conectarse a la base de datos y por ende no pudo guardar el registro del pago. La solución a este error fue cambiar el puerto dentro del archivo .env de la API, colocando el puerto que escucha el contenedor de la base de datos. Se borraron los contendores y se levantaron nuevamente con los cambios aplicados. 