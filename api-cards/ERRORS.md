# 🛠️ Troubleshooting & Incident Runbook — `api-cards`

[![Component](https://img.shields.io/badge/Service-api--cards-512BD4)](README.md)
[![Status](https://img.shields.io/badge/Runbook-Operational-success)](README.md)

This runbook documents runtime anomalies, build issues, and database integration challenges encountered during the delivery of the **Card Management Service** (`api-cards`).

---

## 📋 Issue Log & Solutions

### 1. Database Connection Failure during Container Startup
* **Symptom**: Card creation requests fail with `MySqlException: Unable to connect to any of the specified MySQL hosts.`
* **Root Cause**: The environment variable `DB_HOST` in `.env` was configured to `localhost` instead of the internal Docker bridge network alias `db`.
* **Resolution**:
  Configured `envs/api-cards.env` with the Docker Compose service DNS name:
  ```ini
  DB_HOST=db
  DB_PORT=3306
  DB_NAME=db_tarjetas
  DB_USER=usuario_app
  DB_PASSWORD=secreto
  PORT=8080
  ```

---

### 2. Multi-Stage Build File Resolution Error
* **Symptom**: `docker build` fails at `dotnet restore` with `ApiTarjetas.csproj could not be found`.
* **Root Cause**: Running `docker build` with mismatched build context arguments when referencing project files.
* **Resolution**:
  Execute build from the repository root:
  ```bash
  docker build -t franlopezmora/api-tarjetas:1.0.0 -f api-cards/Dockerfile .
  ```
  The Dockerfile specifies `COPY api-cards/ApiTarjetas.csproj api-cards/` to preserve relative project paths.

---

### 3. Port Binding Mismatch on Minimal API
* **Symptom**: Container runs healthy according to `docker ps`, but HTTP requests return connection refused.
* **Root Cause**: ASP.NET Core 8 defaults to listening on port `8080` (or `5000` depending on `ASPNETCORE_HTTP_PORTS`). If the reverse proxy attempts to communicate on another port, traffic drops.
* **Resolution**:
  Standardized environment variable `PORT=8080` and matched NGINX upstream proxy definition in `nginx.conf`:
  ```nginx
  location /api/cards {
      set $upstream api-cards:8080;
      rewrite ^/api/cards(.*)$ /tarjetas$1 break;
      proxy_pass http://$upstream;
  }
  ```
