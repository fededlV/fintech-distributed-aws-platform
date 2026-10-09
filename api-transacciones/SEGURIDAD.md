# SEGURIDAD — api-transacciones

## Usuario no-root
```dockerfile
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser
```

## Secretos
Credenciales inyectadas por `env_file` en el compose. El archivo `api-transacciones.env` esta en `.gitignore`. Se transfiere a la EC2 por SCP.

## API externa (ipapi.co)
- No requiere API key — llamada anonima.
- Si la API falla, el servicio no falla: guarda la transaccion con `pais: ""` (ver `geolocation.go`). No hay secretos involucrados.
- El contenedor necesita salida a internet. En produccion, limitar a las IPs de `ipapi.co` si se requiere egress filtering.

## Imagen base
`alpine:3.19` — imagen minima (~5MB base), sin shell adicional ni herramientas de sistema innecesarias. Superficie de ataque reducida al minimo.

## Multistage
El SDK de Go, el cache de modulos y el codigo fuente no estan en la imagen final — solo el binario compilado.
