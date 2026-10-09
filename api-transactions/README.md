# 💸 Financial Transactions Service (`api-transactions`)

[![Go](https://img.shields.io/badge/Go-1.22-00ADD8?logo=go&logoColor=white)](https://go.dev/)
[![Alpine Linux](https://img.shields.io/badge/Runtime-Alpine%20(Static%20Binary)-0D597F?logo=alpinelinux&logoColor=white)](https://alpinelinux.org/)
[![Docker](https://img.shields.io/badge/Docker-Multi--Stage%20(15MB)-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![Security](https://img.shields.io/badge/Security-CGO%20Disabled-success)](SECURITY.md)

The **Financial Transactions Service** (`api-transactions`) is a high-concurrency ledger service engineered with the Go standard library (`net/http` and `database/sql`, with zero heavyweight frameworks). It records financial transaction events into the `db_transacciones` schema on MariaDB and enriches transactions with geographic country data based on client origin IP.

---

## 🚀 API Specification & Endpoints

| HTTP Method | Route | Description | Auth / Scope |
|---|---|---|---|
| `GET` | `/` | Service health check | Internal |
| `GET` | `/transacciones` | List all historical transactions | Public / Gateway |
| `GET` | `/transacciones/:id` | Retrieve single transaction by ID | Public / Gateway |
| `POST` | `/transacciones` | Record a new financial transaction | Public / Gateway |
| `PUT` | `/transacciones/:id` | Update transaction metadata | Public / Gateway |
| `DELETE` | `/transacciones/:id` | Delete transaction record | Public / Gateway |

### Sample Payload (`POST` / `PUT`)
```json
{
  "origen_ip": "8.8.8.8",
  "monto": 3000,
  "tipo": "compra"
}
```

### Sample Response (`200 OK`)
```json
{
  "id": 1,
  "origen_ip": "8.8.8.8",
  "monto": 3000,
  "tipo": "compra",
  "pais": "United States",
  "fecha": "2026-10-09T14:32:00Z"
}
```

---

## ⚡ Resilience & Third-Party Fallback Logic

When a transaction is created, the service invokes a geolocation provider (`ipwho.is` / `ipapi.co`) to enrich the transaction with the originating country.
- **Circuit-Breaker & Fallback**: If the external API fails, experiences rate limits, or times out, the service catches the error in `geolocation.go` and safely persists the transaction with `pais: ""`.
- Core financial ledger writes are **never blocked or aborted** due to external API disruptions.

---

## 🛠️ Multi-Stage Container Architecture

Go compiles directly into a standalone machine-code binary. The Docker build utilizes a multi-stage process that isolates the Go SDK in the builder stage and packages only the static executable into an Alpine runner:

```
[ Stage 1: Build (Go 1.22 SDK) ]
golang:1.22
  -> Downloads modules from go.mod / go.sum
  -> Compiles with CGO_ENABLED=0 (statically linked binary, no glibc dependency)
  -> Generates binary: api-transacciones

[ Stage 2: Production Runner (Alpine) ]
alpine:latest
  -> Discards the entire Go SDK, compiler, caches, and source code
  -> Copies ONLY the static binary (~15MB final image size)
  -> Exposes port 8080
```

### Container Resource Governance
Configured via `docker-compose.yml`:
- **CPU Limit**: `0.25`
- **Memory Limit**: `128m`
- **Restart Policy**: `always`

---

## 💻 Local Development (Without Docker)

### Prerequisites
- Go 1.22+
- Accessible MariaDB / MySQL instance

```bash
cd api-transactions

# 1. Download dependencies
go mod tidy

# 2. Configure environment
cp env.example .env
export $(grep -v '^#' .env | xargs)

# 3. Start service
go run .
```

### Quick Verification
```bash
curl http://localhost:8080/transacciones
```

---

## 🐳 Docker Build & Execution

```bash
# Build multi-stage image from root context
docker build -t maxiescgit/api-transacciones:1.0.1 -f api-transactions/Dockerfile .

# Run container with environment configuration
docker run --name api-transactions \
  --env-file ../envs/api-transactions.env \
  -p 8080:8080 \
  maxiescgit/api-transacciones:1.0.1
```

---

## 📚 Related Documentation
- [Security & Hardening Specification](SECURITY.md)
- [Troubleshooting & Error Log](ERRORS.md)
