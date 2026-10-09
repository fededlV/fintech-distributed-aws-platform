# 💳 Payment Processing Service (`api-payments`)

[![Node.js](https://img.shields.io/badge/Node.js-20%20(LTS)-339933?logo=nodedotjs&logoColor=white)](https://nodejs.org/)
[![Express](https://img.shields.io/badge/Express-4.x-000000?logo=express&logoColor=white)](https://expressjs.com/)
[![Alpine Linux](https://img.shields.io/badge/Base%20Image-Alpine%203.19-0D597F?logo=alpinelinux&logoColor=white)](https://alpinelinux.org/)
[![Security](https://img.shields.io/badge/Security-Non--Root%20(node)-success)](SECURITY.md)

The **Payment Processing Service** (`api-payments`) handles payment transactions, currency conversion, and settlement records for the **FinTech Nova** platform. It connects to the `db_pagos` schema on MariaDB and integrates with an external foreign exchange (FX) rate API to automatically calculate USD equivalents.

---

## 🚀 API Specification & Endpoints

| HTTP Method | Route | Description | Auth / Scope |
|---|---|---|---|
| `GET` | `/` | Service health check | Internal |
| `GET` | `/pagos` | Retrieve all payment records | Public / Gateway |
| `GET` | `/pagos/:id` | Retrieve single payment by ID | Public / Gateway |
| `POST` | `/pagos` | Authorize and record payment | Public / Gateway |
| `PUT` | `/pagos/:id` | Update payment details | Public / Gateway |
| `DELETE` | `/pagos/:id` | Void / delete payment record | Public / Gateway |

### Sample Payload (`POST` / `PUT`)
```json
{
  "monto_ars": 50000,
  "medio_pago": "transferencia"
}
```

### Response Example
```json
{
  "id": 1,
  "monto_ars": 50000.00,
  "monto_usd": 41.50,
  "medio_pago": "transferencia",
  "fecha": "2026-10-09T12:00:00.000Z"
}
```

---

## 🛡️ Resilience & Fault Tolerance

During payment creation, the service queries an external real-time exchange rate API (`https://open.er-api.com/v6/latest/ARS`) to compute `monto_usd`.
- **Fault-Tolerant Fallback**: If the external currency provider experiences timeouts, network failure, or HTTP 5xx errors, the request does **not** fail.
- The error is captured gracefully in `src/exchangeRate.js`, and the payment transaction is persisted successfully to MariaDB with `monto_usd: null`.

---

## 🛠️ Container Architecture & Hardening

- **Base Image**: Minimalist `node:20-alpine` reducing image attack surface.
- **Rootless Execution**: Leverages the official non-privileged `node` user (`USER node`).
- **Production Optimization**: `NODE_ENV=production` and `npm ci --only=production` to avoid packaging devDependencies.
- **Resource Constraints** (via `docker-compose.yml`):
  - CPU Limit: `0.25`
  - Memory Limit: `256m`

---

## 💻 Local Development (Without Docker)

### Prerequisites
- Node.js 20+
- Internet connectivity (for exchange rate queries)
- Accessible MariaDB/MySQL instance

```bash
cd api-payments

# 1. Install dependencies
npm install

# 2. Configure environment
cp env.example .env
# Edit .env with database credentials: DB_HOST=localhost, DB_PORT=3306, etc.

# 3. Start development server
npm start
```

### Verification
```bash
curl http://localhost:8080/pagos
curl -X POST http://localhost:8080/pagos \
  -H "Content-Type: application/json" \
  -d '{"monto_ars": 50000, "medio_pago": "transferencia"}'
```

---

## 🐳 Docker Build & Manual Execution

```bash
# Build production image
docker build -t fededlv/api-pagos:1.0.0 .

# Run container with external environment file
docker run --name api-payments \
  --env-file ../envs/api-payments.env \
  -p 8080:8080 \
  fededlv/api-pagos:1.0.0
```

---

## 📚 Related Documentation
- [Security & Hardening Specification](SECURITY.md)
- [Troubleshooting & Error Log](ERRORS.md)
