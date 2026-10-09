# ERRORES — api-facturas

## `ClassNotFoundException` al arrancar el contenedor
**Sintoma:** el contenedor sale con `Unable to start embedded Tomcat` o classpath corrupto.
**Causa:** el `COPY` del stage runtime copiaba el directorio `target/` completo en lugar del `.jar` final.
**Resolucion:**
```dockerfile
COPY --from=build /app/target/api-facturas-*.jar app.jar
```

## `Communications link failure` — no conecta a la DB
**Sintoma:** error de conexion a MariaDB apenas arranca el contenedor.
**Causa:** api-facturas inicia antes de que MariaDB termine de inicializar las bases.
**Resolucion:** `depends_on: db` en el compose garantiza que el *contenedor* de DB arranco, no que la DB esta lista. Se resuelve con `restart: always` — Docker reinicia el servicio hasta que la conexion funciona.

## `mvn package` falla en el build por falta de memoria
**Sintoma:** el stage de build muere con `OutOfMemoryError` o el proceso Maven es matado por el SO.
**Causa:** Maven + compilacion Java consumen bastante RAM en un entorno restringido.
**Resolucion:** agregar `MAVEN_OPTS=-Xmx512m` antes del `RUN mvn package` en el Dockerfile.
