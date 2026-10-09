# 🛠️ System Incident Post-Mortems & Troubleshooting Runbook

[![Status: Documented](https://img.shields.io/badge/Post--Mortems-Resolved-success)](README.md)
[![Operational Excellence](https://img.shields.io/badge/Reliability-SRE%20Runbook-blue)](README.md)

This runbook documents production deployment incidents, operational anomalies, root cause analyses (RCA), and preventative mitigations encountered during the orchestration and deployment of the **FinTech Nova** platform on AWS EC2.

---

## 📋 Incident Index

1. [INC-01: Environment Variable Directory Path Mismatch](#inc-01-environment-variable-directory-path-mismatch)
2. [INC-02: Cluster-Wide Database Connection Failure (HTTP 500 Smoke Test Outage)](#inc-02-cluster-wide-database-connection-failure-http-500-smoke-test-outage)
3. [INC-03: Upstream Timeout & Cold-Start 502 Gateway Error on Java Spring Boot](#inc-03-upstream-timeout--cold-start-502-gateway-error-on-java-spring-boot)
4. [INC-04: Third-Party Geolocation Provider Rate-Limiting on AWS Public IP](#inc-04-third-party-geolocation-provider-rate-limiting-on-aws-public-ip)

---

### INC-01: Environment Variable Directory Path Mismatch

* **Severity**: Medium (Build / Deploy Failure)
* **Affected Component**: `deploy.sh` & Container Orchestration
* **Symptom**:
  ```text
  env file /home/ec2-user/tp-grupo16/api-pagos.env not found: stat /home/ec2-user/tp-grupo16/api-pagos.env: no such file or directory
  ```

#### Root Cause Analysis (RCA)
To improve security governance, environment variables were migrated from loose files in the project root into a centralized, protected directory (`envs/`). However, the paths referenced in `docker-compose.yml` and the SCP file transfer commands in `deploy.sh` were temporarily out of alignment, causing Docker Compose to abort when attempting to mount missing `.env` paths.

#### Resolution & Mitigation
1. Standardized all environment file references in `docker-compose.yml` to the uniform pattern: `env_file: envs/<service-name>.env`.
2. Updated `deploy.sh` to recursively synchronize the entire `envs/` directory to the target EC2 workspace (`scp -r $SSH_OPTS envs $REMOTE_USER@$EC2_IP:$REMOTE_DIR/`).
3. Re-ran `docker compose pull && docker compose up -d` to verify consistent mounting across all services.

---

### INC-02: Cluster-Wide Database Connection Failure (HTTP 500 Smoke Test Outage)

* **Severity**: High (Service Outage)
* **Affected Component**: All polyglot backend APIs (`api-clients`, `api-payments`, `api-invoices`, `api-transactions`, `api-cards`)
* **Symptom**:
  ```text
  [FAIL] https://54.81.15.185/api/clientes responded 500
  [FAIL] https://54.81.15.185/api/pagos responded 500
  [FAIL] https://54.81.15.185/api/facturas responded 502
  [FAIL] https://54.81.15.185/api/transacciones responded 500
  [FAIL] https://54.81.15.185/api/tarjetas responded 500
  ```

#### Root Cause Analysis (RCA)
Within Docker bridge networking, container-to-container communication relies on Docker's embedded DNS server resolving the service key defined in `docker-compose.yml` (in this architecture, `db`). The initial environment variables configured `DB_HOST` to `localhost` or an external IP instead of the internal service alias `db`. Consequently, the APIs failed to establish TCP handshakes with MariaDB on port `3306`, triggering internal server errors.

#### Resolution & Mitigation
1. Corrected all `DB_HOST` values across `envs/*.env` to target the internal network hostname: `DB_HOST=db`.
2. Verified that all containers belonged to the shared bridge network (`tp-network`).
3. Executed automated redeployment via `deploy.sh`, confirming successful container reboot and database connection pooling.

---

### INC-03: Upstream Timeout & Cold-Start 502 Gateway Error on Java Spring Boot

* **Severity**: Medium (Deployment Health Check Flapping)
* **Affected Component**: `api-invoices` (Java 17 / Spring Boot)
* **Symptom**:
  ```text
  [FAIL] https://54.81.15.185/api/facturas responded 502 Bad Gateway
  ```

#### Root Cause Analysis (RCA)
The JVM runtime for Spring Boot requires a longer initialization and warmup phase (JIT compilation, classpath scanning, Flyway/Hibernate validation) than lightweight runtimes such as Go or Node.js. The original smoke test script utilized a static 25-second `sleep` before querying the endpoint. Because `api-invoices` was still starting embedded Tomcat, NGINX returned `502 Bad Gateway`.

#### Resolution & Mitigation
Replaced static wait timers in `deploy.sh` with an **intelligent exponential-backoff / polling retry loop**:
```bash
# Polling mechanism: 12 attempts x 5 seconds = up to 60 seconds of resilience
MAX_INTENTOS=12
for URL in "${ENDPOINTS[@]}"; do
    for ((i=1; i<=MAX_INTENTOS; i++)); do
        STATUS=$(curl -k -s -o /dev/null -w "%{http_code}" "$URL" || echo "Error")
        if [ "$STATUS" == "200" ]; then
            echo "[OK]"
            break
        fi
        sleep 5
    done
done
```
This ensures zero false-negative failures during deployment while allowing fast-booting services to be verified immediately.

---

### INC-04: Third-Party Geolocation Provider Rate-Limiting on AWS Public IP

* **Severity**: Low (Graceful Degradation / Metadata Enrichment Missing)
* **Affected Component**: `api-transactions` (Go) & Geolocation Service
* **Symptom**:
  New financial transactions were created successfully, but the `pais` (country) field consistently returned empty (`""`) in the UI when running on AWS EC2.

#### Root Cause Analysis (RCA)
1. In development, the free tier of `ipapi.co` functioned without restriction on residential IPs.
2. When deployed to AWS EC2, the public IP range triggered strict cloud IP rate limits on `ipapi.co`, which returned HTTP `429 Too Many Requests` (`RateLimited`).
3. **Resilience in Action**: Because `api-transactions` was designed with fault-tolerant error boundaries in `geolocation.go`, it intercepted the external HTTP failure and safely defaulted `pais: ""` without failing the primary database write.

#### Resolution & Mitigation
1. **Architectural Code Update**: Refactored `geolocation.go` to utilize `ipwho.is`, a cloud-friendly geolocation API with generous rate allowances for AWS IP ranges.
2. **Container Lifecycle**: Rebuilt the Go microservice binary using multi-stage compilation (`CGO_ENABLED=0`), tagged image version `1.0.1`, pushed to Docker Hub, and rolled out a rolling container update on the cluster.
3. Country metadata now enriches accurately across all transaction logs.
