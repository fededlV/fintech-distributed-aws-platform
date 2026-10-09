# Registro y Solución de Errores en la API de Clientes.
Se registran los erorres que se tuvieron a la hora de armar, y también correr los contenedores que contienen la API de clientes. Se documentan los errores y sus soluciones para futuras referencias.



## Soluciones realizadas.

1. Cuando quise probar localmente el servicio, me di con que no podía conectarme a la base de datos, ya que no estaba corriendo. Para solucionarlo, Esto lo realicé levantando un contenedor local de Docker con la imagen de la base de datos correspondiente y asegurándome de que los puertos estuvieran correctamente mapeados. Una vez hecho esto, pude conectarme exitosamente a la base de datos y continuar con las pruebas locales del servicio.


# Errores y Soluciones realizadas. 
Son errores que pueden ocurrir al ejecutar el contenedor de la API de clientes, y sus posibles soluciones:

- **Error:** Prueba local inicial, falla con la base de datos.
- **Solución:** Cuando quise probar localmente el servicio, me di con que no podía conectarme a la base de datos, ya que no estaba corriendo. Para solucionarlo, Esto lo realicé levantando un contenedor local de Docker con la imagen de la base de datos correspondiente y asegurándome de que los puertos estuvieran correctamente mapeados. Una vez hecho esto, pude conectarme exitosamente a la base de datos y continuar con las pruebas locales del servicio.
-------------------------------------------------------------------------------------------------------------------------
- **Fallo de permisos:** Si intentamos escribir logs o archivos como un usuario no-root, puede fallar si no se cambian los permisos antes de arrancar.
- **Solución:** Se usa `RUN chown -R appuser:appuser /app` antes de cambiar a `USER appuser`. 
------------------------------------------------------------------------------------------------------------------------
- **No encuentre el comando "flask" o las líbrerias:** 
- **Solución:** Al definir explícitamente la variable de entorno `ENV PATH="/opt/venv/bin:$PATH"` nos aseguramos de que el sistema del contenedor siempre use nuestro entorno virtual.
-------------------------------------------------------------------------------------------------------------------------
- **Error de conexión a la base de datos:** Si la API no puede conectarse a la base de datos, puede deberse a que el contenedor de la base de datos no está corriendo o los puertos no están correctamente mapeados.
- **Solución:** El error que se documenta hace referencia a un error que se dio al momento de probar crear un cliente, es decir que la API no pudo guardar el registro en la base de datos. Lo que causo este error, fue que se configuró de forma incorrecta el puerto dentro del archivo .env de la API, colocando la variable del nombre del contenedor de la base de datos incorrectamente y también se colocó puerto que escucha el host y no el puerto que escucha el contenedor de la base de datos, por lo que la API no pudo conectarse a la base de datos y por ende no pudo guardar el registro del pago. La solución a este error fue cambiar el puerto dentro del archivo .env de la API, colocando el puerto que escucha el contenedor de la base de datos. Se borraron los contendores y se levantaron nuevamente con los cambios aplicados. 
-------------------------------------------------------------------------------------------------------------------------
- **Error de creación de cliente por permisos**
- **Solución:** Se tenía configurado de manera incorrecta el usuario y contraseña dentro del archivo .env local, que no concordaba con el usuario y contraseña que se configuró en la base de datos, por lo que la API no pudo conectarse a la base de datos y por ende no pudo guardar el registro del cliente. La solución a este error fue cambiar el usuario y contraseña dentro del archivo .env de la API, colocando el usuario y contraseña que escucha el contenedor de la base de datos. Se borraron los contendores y se levantaron nuevamente con los cambios aplicados.