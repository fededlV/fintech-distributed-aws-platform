# web (Vite)

Panel único que consume las 5 APIs del TP (clientes, pagos, facturas, transacciones, tarjetas).
Es JavaScript vanilla + Vite (sin framework), pensado para mantener el ejercicio de Docker en
foco. Todas las llamadas van a rutas relativas `/api/<servicio>/...`.

## Cómo levantar en LOCAL (sin Docker)

### Opción A: con `npm run dev` (recomendado para desarrollar el front)
Vite trae un proxy configurado en `vite.config.js` que redirige cada `/api/<servicio>` al puerto
correspondiente en tu máquina. Para que funcione, corran las 5 APIs sueltas (ver el `README.md`
de cada `api-*`) en estos puertos:

| Servicio            | Puerto sugerido en local |
|----------------------|--------------------------|
| api-clientes         | 8081                     |
| api-pagos            | 8082                     |
| api-facturas         | 8083                     |
| api-transacciones    | 8084                     |
| api-tarjetas         | 8085                     |

```sh
cd web
npm install
npm run dev
```
Abrir `http://localhost:5173`.

### Opción B: build + servir estático (simula producción)
```sh
cd web
npm install
npm run build      # genera dist/
npm run preview    # sirve dist/ en un puerto local, PERO sin el proxy de /api
```
Para probar `/api/...` de verdad como en producción hace falta el reverse proxy de NGINX — por
eso el flujo real de este TP es dockerizar `web/` con NGINX sirviendo `dist/` (ver Dockerfile a
crear) y usando `nginx/nginx.conf`, que ya viene armado con los 5 proxys.

## Docker
Este directorio **no incluye Dockerfile** — es parte de la consigna del TP escribirlo (multistage:
`node` para `npm run build`, `nginx` para servir `dist/` + `nginx/nginx.conf`). Ver el
`README.md` en la raíz de `tp-2026/`.

## Dockerizacion

### Dockerfile (multistage)
- **Stage build:** `node:20-alpine` — `npm ci` + `npm run build` → genera `dist/`.
- **Stage runtime:** `nginx:alpine` — sirve `dist/` y actua como reverse proxy hacia las 5 APIs.
- TLS generado en **runtime** por `entrypoint.sh` al arrancar el contenedor (ver `SEGURIDAD.md`).
- NGINX escucha solo en puerto 443 (HTTPS). Puerto 80 no se expone en ningun lado.

### Build y run manual
```sh
docker build -t web:test -f web/Dockerfile .
docker run -p 8443:443 web:test
# abrir https://localhost:8443 (aceptar warning de certificado autofirmado)
```

### Imagen en Docker Hub
`<usuario>/web:1.0.0`
