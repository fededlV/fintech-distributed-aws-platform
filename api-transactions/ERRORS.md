# 🛠️ Troubleshooting & Incident Runbook — `api-transactions`

[![Component](https://img.shields.io/badge/Service-api--transactions-00ADD8)](README.md)
[![Status](https://img.shields.io/badge/Runbook-Operational-success)](README.md)

This runbook documents compilation errors, library linking anomalies, and external rate-limiting incidents encountered during the containerization and operation of the **Financial Transactions Service** (`api-transactions`).

---

## 📋 Issue Log & Solutions

### 1. Runtime Crash on Alpine Linux (`exec format error`)
* **Symptom**: The Alpine container exits immediately upon launch:
  ```text
  exec /app/api-transactions: exec format error
  ```
* **Root Cause**: The Go binary was compiled with CGO enabled (`CGO_ENABLED=1`), which links dynamically against GNU `glibc`. Because Alpine Linux uses `musl libc` instead of `glibc`, the dynamic linker fails to execute the binary.
* **Resolution**:
  Enforced static compilation without CGO in the Dockerfile build step:
  ```dockerfile
  RUN CGO_ENABLED=0 go build -o api-transactions .
  ```
  This creates a self-contained, statically linked executable compatible with Alpine and minimal container runtimes.

---

### 2. Module Verification Failure (`go: missing go.sum entry`)
* **Symptom**: `docker build` fails during module download with:
  ```text
  go: github.com/go-sql-driver/mysql@v1.8.1: missing go.sum entry; to add it: go mod download
  ```
* **Root Cause**: The local `go.sum` checksum file was desynchronized after dependency updates and was missing cryptographic hash entries for transitive packages.
* **Resolution**:
  Executed module reconciliation before building the container:
  ```bash
  go mod tidy
  git add go.mod go.sum
  ```

---

### 3. Missing Geolocation Country Metadata on AWS EC2 Cloud Instances
* **Symptom**: In local development, transactions recorded country names (e.g. `"United States"`), but on the AWS EC2 instance, the field consistently returned empty string `""`.
* **Root Cause**: The free tier of the original third-party provider (`ipapi.co`) enforces strict request quotas on public cloud IP ranges (AWS EC2). When queries originated from the EC2 instance, the provider responded with HTTP `429 Too Many Requests`.
* **Resilience Demonstration**: The application did not crash or roll back transactions because `geolocation.go` gracefully trapped the HTTP error and saved the record with `pais: ""`.
* **Permanent Resolution**: Refactored `geolocation.go` to utilize `ipwho.is`, which offers higher request thresholds for cloud endpoints, rebuilt the container image (`v1.0.1`), and redeployed.
