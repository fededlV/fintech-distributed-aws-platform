# ERRORES — api-transacciones

## `exec format error` al arrancar en Alpine
**Sintoma:** el contenedor sale inmediatamente con `exec /app/api-transacciones: exec format error`.
**Causa:** el binario fue compilado sin `CGO_ENABLED=0`, incluyendo dependencias de glibc que no existen en Alpine.
**Resolucion:**
```dockerfile
RUN CGO_ENABLED=0 GOOS=linux go build -o api-transacciones .
```

## `go: missing go.sum entry` durante el build
**Sintoma:** el stage de build falla al compilar porque faltan entradas en `go.sum`.
**Causa:** el `go.sum` desincronizado o ausente del repo.
**Resolucion:** correr `go mod tidy` localmente y commitear el `go.sum` actualizado antes de buildear la imagen.

## Campo `pais` siempre vacio en la EC2
**Sintoma:** las transacciones se guardan con `pais: ""` aunque la API de geolocalizacion funciona en local.
**Causa:** el Security Group de la EC2 bloqueaba el trafico saliente hacia `ipapi.co` (puerto 443).
**Resolucion:** verificar que la regla de salida del Security Group permite TCP 443 hacia `0.0.0.0/0`. El codigo maneja el fallo correctamente (guarda sin el campo), pero si la conectividad existe el campo se completa.

- Campo "pais" en blanco al listar las transacciones en la interfaz
    - Se debe a un bloqueo por límite de peticiones (Rate Limiting) de la API pública externa de geolocalización (`ipapi.co`) al consultar desde la instancia EC2. Al provenir las peticiones de una IP pública de AWS, la capa gratuita limitaba rápidamente el acceso respondiendo con un error (`RateLimited`). Como el microservicio `api-transacciones` está programado de forma resiliente, atrapaba este error de terceros y dejaba el país en blanco (`""`) para evitar que fallara la creación de la transacción en la base de datos. Se solucionó modificando el archivo `geolocation.go` para utilizar una API alternativa (`ipwho.is`) que es menos restrictiva con IPs de la nube, y luego construyendo y redesplegando la nueva versión de la imagen Docker en el clúster.
