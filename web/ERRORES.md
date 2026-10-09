# ERRORES — web

## 502 Bad Gateway en `/api/*`
**Sintoma:** el frontend carga pero todas las llamadas a la API devuelven 502.
**Causa:** los nombres de upstream en `nginx.conf` no coincidian con los nombres de servicios en el `docker-compose.yml`.
**Resolucion:** los nombres en `nginx.conf` (`api-facturas`, `api-transacciones`, etc.) deben coincidir exactamente con los nombres de servicio del compose. Docker resuelve DNS internamente por nombre de servicio dentro de la red compartida.

## `ERR_SSL_PROTOCOL_ERROR` en el navegador
**Sintoma:** el navegador rechaza la conexion con error de protocolo (no el warning habitual de certificado no confiable).
**Causa:** NGINX arrancaba antes de que `entrypoint.sh` terminara de generar el certificado.
**Resolucion:** agregar validacion en el entrypoint antes de lanzar NGINX:
```sh
nginx -t && exec nginx -g 'daemon off;'
```
`nginx -t` valida la config (incluyendo que los archivos de cert existen) y falla antes de lanzar si algo falta.

## `npm ci` falla — `package-lock.json` no encontrado
**Sintoma:** el stage de build falla con error de lockfile desincronizado o ausente.
**Causa:** `package-lock.json` no estaba commiteado en el repo.
**Resolucion:** correr `npm install` localmente para generarlo y commitearlo. `npm ci` requiere el lockfile — es mas estricto que `npm install` y por eso preferible en Docker.

## NGINX no encuentra `dist/` en la imagen final
**Sintoma:** el contenedor arranca pero devuelve 404 en `/`.
**Causa:** el `COPY --from=build` en el Dockerfile apuntaba a una ruta incorrecta del stage de build.
**Resolucion:** verificar que Vite genera en `dist/` (es el default) y que el COPY es:
```dockerfile
COPY --from=build /app/dist /usr/share/nginx/html
```
