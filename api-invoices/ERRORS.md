# 🛠️ Troubleshooting & Incident Runbook — `api-invoices`

[![Component](https://img.shields.io/badge/Service-api--invoices-ED8B00)](README.md)
[![Status](https://img.shields.io/badge/Runbook-Operational-success)](README.md)

This runbook documents JVM initialization errors, Maven build constraints, and database race conditions encountered during the deployment of the **Invoicing & Billing Service** (`api-invoices`).

---

## 📋 Issue Log & Solutions

### 1. Embedded Tomcat Startup Failure (`ClassNotFoundException`)
* **Symptom**: The container exits on boot with `Unable to start embedded Tomcat` or corrupted JAR execution errors.
* **Root Cause**: The runtime Docker stage used a wildcard `COPY --from=build /app/target/ /app/` copying intermediate Maven artifacts and test classes rather than the packaged Spring Boot executable JAR.
* **Resolution**:
  Targeted only the compiled JAR file:
  ```dockerfile
  COPY --from=build /app/target/api-facturas.jar .
  CMD ["java", "-Xmx256m", "-jar", "api-facturas.jar"]
  ```

---

### 2. Database Race Condition on Boot (`Communications link failure`)
* **Symptom**: Spring Boot crashes immediately after boot with:
  ```text
  Communications link failure: The last packet successfully received from the server was 0 milliseconds ago.
  ```
* **Root Cause**: The Docker Compose directive `depends_on: db` guarantees that the database container has started its operating system process, but not that MariaDB has completed its internal schema migrations and opened TCP port 3306.
* **Resolution**:
  - Implemented `restart: always` in `docker-compose.yml`, allowing Docker Engine to automatically restart the service container until the database connection pool succeeds.
  - Implemented retry polling within the deployment health check script (`deploy.sh`).

---

### 3. Maven Build Killed During Multi-Stage Compilation (OOM)
* **Symptom**: `docker build` fails with `The command '/bin/sh -c mvn package' returned a non-zero code: 137` (SIGKILL / Out-Of-Memory).
* **Root Cause**: Maven and javac compilation together exceeded host memory limits during dependency resolution on memory-constrained virtual machines.
* **Resolution**:
  Configured explicit JVM memory parameters for the Maven compilation process:
  ```dockerfile
  ENV MAVEN_OPTS="-Xmx512m"
  RUN mvn package -DskipTests
  ```
