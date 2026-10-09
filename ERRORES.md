- Correr deploy.sh: "env file /home/ec2-user/tp-grupo16/api-pagos.env not found: stat /home/ec2-user/tp-grupo16/api-pagos.env: no suchfile or directory"
    - Se debe a que como implementamos el uso de las variables de entorno dentro de una carpeta para tenerlas centralizadas y hacer que el despliegue sea más sencillo, y debido a esto debemos actualizar el docker-compose para asignar correctamente las variables de entorno. 

- Fallo de Smoke Test: 
    """[FALLO] https://54.81.15.185/api/clientes respondió 500
    [FALLO] https://54.81.15.185/api/pagos respondió 500
    [FALLO] https://54.81.15.185/api/facturas respondió 502
    [FALLO] https://54.81.15.185/api/transacciones respondió 500
    [FALLO] https://54.81.15.185/api/tarjetas respondió 500"""
    - Se debe al falló en la conexión con la base de datos, ya que se especificaba de forma incorrecta el hostname y no estaba alineado con el que se especifica en el docker-compose.yml. Luego de este cambio, al correr nuevamente el script deploy.sh copiará la carpeta envs/ con los valores corregidos a la EC2. Cuando haga docker compose up -d, Docker detectará que los .env cambiaron, reiniciará los contenedores de las APIs, y esta vez se conectarán exitosamente al contenedor db

- Fallo 502 en servicio de facturas hecho con Java
    - Al principio teniamos configurado para que el script realicé el smoke test a los 25 segundos, y al ejecutarse y llegar al api-facturas, este todavía se estaba cargando, por ende daba error al hacer la request. Ahora aplicamos una tecnica de reintentos en nuestro script para hacer el curl hasta que todos los servicios respondan un código 200. 
- Campo "pais" en blanco al listar las transacciones en la interfaz
    - Se debe a un bloqueo por límite de peticiones (Rate Limiting) de la API pública externa de geolocalización (`ipapi.co`) al consultar desde la instancia EC2. Al provenir las peticiones de una IP pública de AWS, la capa gratuita limitaba rápidamente el acceso respondiendo con un error (`RateLimited`). Como el microservicio `api-transacciones` está programado de forma resiliente, atrapaba este error de terceros y dejaba el país en blanco (`""`) para evitar que fallara la creación de la transacción en la base de datos. Se solucionó modificando el archivo `geolocation.go` para utilizar una API alternativa (`ipwho.is`) que es menos restrictiva con IPs de la nube, y luego construyendo y redesplegando la nueva versión de la imagen Docker en el clúster.
