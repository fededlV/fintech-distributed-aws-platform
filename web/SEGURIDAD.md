# SEGURIDAD — web

## Certificado TLS — generacion en runtime

El certificado autofirmado y la clave privada se generan al arrancar el contenedor mediante `entrypoint.sh`:

```sh
#!/bin/sh
mkdir -p /etc/nginx/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/key.pem \
  -out /etc/nginx/ssl/cert.pem \
  -subj "/CN=tp-devops-grupo16"
nginx -t && exec nginx -g 'daemon off;'
```

![Advertencia de Certificado TLS](capturas/advertencia_tls.png)

**Por que runtime y no build-time:**
Si el certificado se generara en el `Dockerfile`, la clave privada quedaria embebida en cada capa de la imagen publica de Docker Hub — descargable por cualquier persona. La generacion en runtime mantiene la clave fuera de la imagen y del repositorio. La clave se genera en memoria del contenedor en cada arranque y no se persiste en ningun volumen.

## HTTPS obligatorio — puerto 80 cerrado
NGINX escucha unicamente en el puerto 443 (HTTPS). El puerto 80 no esta presente en el `nginx.conf`, no se expone en el compose ni esta abierto en el Security Group de la EC2.

## server_tokens off
El `nginx.conf` incluye `server_tokens off` para que NGINX no exponga su version en los headers de respuesta.

## Usuario NGINX
La imagen `nginx:alpine` corre los workers como usuario `nginx` (no root). El proceso master necesita ser root solo para abrir el puerto 443 (menor a 1024), que es el comportamiento estandar de NGINX.

## Imagen base
`nginx:alpine` — imagen oficial minima. Sin herramientas de build ni el codigo fuente de Vite en la imagen final.

## Secretos
`web` no tiene credenciales propias (no conecta a la DB). No requiere `env_file`. El unico "secreto" es el certificado TLS, que se genera en runtime y nunca toca el repositorio.
