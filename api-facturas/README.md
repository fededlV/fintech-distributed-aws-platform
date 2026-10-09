# api-facturas (Java / Spring Boot)

ABM de facturas de *FinTech Nova*. Usa la base `db_facturas` (misma instancia compartida de
MariaDB que las otras 4, ver `../db/`).

## Endpoints
| Método | Ruta            | Descripción     |
|--------|-----------------|------------------|
| GET    | `/facturas`     | Listar todas     |
| GET    | `/facturas/:id` | Obtener una      |
| POST   | `/facturas`     | Crear (alta)     |
| PUT    | `/facturas/:id` | Modificar        |
| DELETE | `/facturas/:id` | Borrar (baja)    |

Body de ejemplo (`POST` / `PUT`):
```json
{ "numero": "A-0003", "monto": 12000.50, "clienteId": 1, "fechaEmision": "2026-03-01" }
```

## Cómo levantar en LOCAL (sin Docker)

Requisitos: JDK 21+, Maven 3.9+, una base MariaDB/MySQL accesible.

```sh
cd api-facturas
cp env.example .env
export $(grep -v '^#' .env | xargs)
# Si corren las 5 APIs juntas en el host para probar con el front de Vite,
# usen PORT=8083 antes de arrancar (export PORT=8083).

mvn spring-boot:run
```

Probar:
```sh
curl http://localhost:8080/facturas
```

## Docker
Este directorio **no incluye Dockerfile** — es parte de la consigna del TP escribirlo (ver el
`README.md` en la raíz de `tp-2026/`). Pista: acá el multistage (compilar con Maven, correr con
un JRE) no es opcional si quieren una imagen final liviana.

## Dockerizacion

### Dockerfile (multistage)
- **Stage build:** `maven:3.9-eclipse-temurin-21` — copia `pom.xml`, descarga dependencias, copia `src/`, ejecuta `mvn package -DskipTests`.
- **Stage runtime:** `eclipse-temurin:21-jre` — copia solo el `.jar` generado. Imagen final ~270MB vs ~700MB con JDK completo.
- Heap JVM limitado a `-Xmx384m` en el `CMD` para convivir con los otros servicios en una EC2 t3.medium.
- Usuario no-root: se crea `appuser` y se ejecuta con `USER appuser`.

### Variables de entorno requeridas
| Variable | Ejemplo |
|---|---|
| DB_HOST | db |
| DB_PORT | 3306 |
| DB_NAME | db_facturas |
| DB_USER | usuario_app |
| DB_PASSWORD | secreto |
| PORT | 8080 |

### Imagen en Docker Hub
`<usuario>/api-facturas:1.0.0`

### Build y run manual
```sh
docker build -t api-facturas:test -f api-facturas/Dockerfile .
docker run --env-file api-facturas.env -p 8080:8080 api-facturas:test
curl http://localhost:8080/facturas
```
