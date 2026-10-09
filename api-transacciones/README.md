# api-transacciones (Go)

ABM de transacciones de *FinTech Nova*, escrito con la librería estándar de Go
(`net/http` + `database/sql`, sin frameworks). Usa la base `db_transacciones` (misma instancia
compartida de MariaDB que las otras 4, ver `../db/`). Al crear o modificar una transacción, esta
API llama a una **API pública externa** (`https://ipapi.co`, sin API key) para geolocalizar la
IP de origen y completar el campo `pais`. Si esa API externa no responde, la transacción se
guarda igual con `pais: ""` (ver `geolocation.go`).

## Endpoints
| Método | Ruta                  | Descripción     |
|--------|------------------------|------------------|
| GET    | `/`                    | Health check     |
| GET    | `/transacciones`       | Listar todas     |
| GET    | `/transacciones/:id`   | Obtener una      |
| POST   | `/transacciones`       | Crear (alta)     |
| PUT    | `/transacciones/:id`   | Modificar        |
| DELETE | `/transacciones/:id`   | Borrar (baja)    |

Body de ejemplo (`POST` / `PUT`):
```json
{ "origen_ip": "8.8.8.8", "monto": 3000, "tipo": "compra" }
```

## Cómo levantar en LOCAL (sin Docker)

Requisitos: Go 1.22+, acceso a internet (para la API de geolocalización), una base
MariaDB/MySQL accesible.

```sh
cd api-transacciones
go mod tidy   # descarga el driver de MySQL (github.com/go-sql-driver/mysql)

cp env.example .env
export $(grep -v '^#' .env | xargs)
# Si corren las 5 APIs juntas en el host para probar con el front de Vite,
# usen PORT=8084 antes de arrancar (export PORT=8084).

go run .
```

Probar:
```sh
curl http://localhost:8080/transacciones
```

## Docker
Este directorio **no incluye Dockerfile** — es parte de la consigna del TP escribirlo (ver el
`README.md` en la raíz de `tp-2026/`). Pista: Go compila a un binario estático, así que el
multistage acá te puede dejar una imagen final buscando solo `FROM scratch` o `alpine`.

## Dockerizacion

### Dockerfile (multistage)
- **Stage build:** `golang:1.22-alpine` — descarga modulos, compila con `CGO_ENABLED=0 GOOS=linux go build -o api-transacciones .`.
- **Stage runtime:** `alpine:3.19` — solo el binario compilado. Imagen final ~15MB.
- `CGO_ENABLED=0` es obligatorio para que el binario sea estatico y compatible con Alpine (que usa musl, no glibc).
- El contenedor necesita salida a internet en runtime para llamar a `ipapi.co`.
- Usuario no-root: se crea `appuser` con `adduser -S` y se ejecuta con `USER appuser`.

### Variables de entorno requeridas
| Variable | Ejemplo |
|---|---|
| DB_HOST | db |
| DB_PORT | 3306 |
| DB_NAME | db_transacciones |
| DB_USER | usuario_app |
| DB_PASSWORD | secreto |
| PORT | 8080 |

### Imagen en Docker Hub
`<usuario>/api-transacciones:1.0.0`

### Build y run manual
```sh
docker build -t api-transacciones:test -f api-transacciones/Dockerfile .
docker run --env-file api-transacciones.env -p 8080:8080 api-transacciones:test
curl -X POST http://localhost:8080/transacciones \
  -H "Content-Type: application/json" \
  -d '{"origen_ip":"8.8.8.8","monto":3000,"tipo":"compra"}'
```
