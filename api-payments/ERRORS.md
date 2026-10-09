# 🛠️ Troubleshooting & Incident Runbook — `api-payments`

[![Component](https://img.shields.io/badge/Service-api--payments-339933)](README.md)
[![Status](https://img.shields.io/badge/Runbook-Operational-success)](README.md)

This runbook documents container build anomalies, Docker context issues, and database integration challenges encountered during the delivery of the **Payment Processing Service** (`api-payments`).

---

## 📋 Issue Log & Solutions

### 1. Docker Registry Image Manifest Not Found
* **Symptom**:
  ```text
  Error response from daemon: manifest for fededlv/api-pagos:1.0.0 not found: manifest unknown
  ```
* **Root Cause**: The container orchestration file attempted to pull the tagged image from Docker Hub before it had been built and pushed to the remote repository.
* **Resolution**:
  Built and tagged the image locally before testing, or executed the unified release pipeline:
  ```bash
  # Local build command:
  docker build -t fededlv/api-pagos:1.0.0 api-payments/
  # Push to registry:
  docker push fededlv/api-pagos:1.0.0
  ```

---

### 2. Docker Build Context Mismatch on `package*.json`
* **Symptom**:
  ```text
  Step 6/10 : COPY --chown=node:node package*.json ./
  COPY failed: no source files were specified
  ```
* **Root Cause**: The `docker build` command was executed with the context set to the project root while the `Dockerfile` expected the context to be inside the `api-payments/` directory (or vice versa).
* **Resolution**:
  Navigated directly into the microservice directory before invoking build commands:
  ```bash
  cd api-payments
  docker build -t fededlv/api-pagos:1.0.0 .
  ```
  Alternatively, aligned path definitions when building from the root repository directory.

---

### 3. Payment Creation Failure (`{"error": "Error al crear el pago"}`)
* **Symptom**: HTTP 500 error returned by Express when invoking `POST /pagos`.
* **Root Cause**: The `.env` file specified the external host port (`3307` or `localhost`) instead of the internal container network address (`db:3306`), preventing the Node.js database pool from connecting to MariaDB.
* **Resolution**:
  Corrected database parameters in `envs/api-payments.env`:
  ```ini
  DB_HOST=db
  DB_PORT=3306
  DB_NAME=db_pagos
  DB_USER=usuario_app
  DB_PASSWORD=secreto
  PORT=8080
  ```
  Restarted the container to re-initialize connection pooling.