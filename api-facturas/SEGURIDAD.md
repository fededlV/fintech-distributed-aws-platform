# SEGURIDAD — api-facturas

## Usuario no-root
```dockerfile
RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser
USER appuser
```
El proceso de la JVM corre como `appuser`, sin privilegios de root dentro del contenedor.

## Secretos
Las credenciales de la DB (`DB_USER`, `DB_PASSWORD`) se inyectan exclusivamente por `env_file` en el compose. El archivo `api-facturas.env` esta en `.gitignore` y se transfiere a la EC2 por SCP. Nunca esta hardcodeado en el `Dockerfile` ni en el `docker-compose.yml`.

## Imagen base
`eclipse-temurin:21-jre` — imagen oficial de Eclipse Temurin (Adoptium), solo JRE sin herramientas de desarrollo. Reduce superficie de ataque vs imagen con JDK completo.

## Multistage
El stage de build (`maven:3.9-eclipse-temurin-21`) no llega a la imagen final. Las herramientas de compilacion, el codigo fuente y el cache de Maven no estan presentes en produccion.
