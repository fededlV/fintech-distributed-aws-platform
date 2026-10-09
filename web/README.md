# 🌐 Web Gateway & Frontend Application (`web`)

[![Vite](https://img.shields.io/badge/Vite-5.x-646CFF?logo=vite&logoColor=white)](https://vitejs.dev/)
[![NGINX](https://img.shields.io/badge/NGINX-Alpine%20Reverse%20Proxy-009639?logo=nginx&logoColor=white)](https://nginx.org/)
[![TLS/HTTPS](https://img.shields.io/badge/SSL%2FTLS-Runtime%20Ephemeral-success)](SECURITY.md)
[![Docker](https://img.shields.io/badge/Docker-Multi--Stage%20Build-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)

The **Web Gateway & Frontend Application** (`web`) serves as the unified entrypoint and Single-Page Application (SPA) dashboard for the **FinTech Nova** platform. It combines a lightweight frontend interface with an **NGINX reverse proxy gateway** that terminates TLS and intelligently routes traffic across all 5 backend microservices.

---

## 🏛️ Routing & Ingress Architecture

All external platform requests enter exclusively via HTTPS (`port 443`). NGINX inspects the request URI and routes it to the corresponding internal container on Docker's private bridge network:

```
                            HTTPS :443
                               |
                               v
                     +--------------------+
                     |    NGINX Gateway   |
                     |  (TLS Termination) |
                     +---------+----------+
                               |
         +---------------------+---------------------+
         |           |            |           |      |
         v           v            v           v      v
     /api/clients  /api/payments /api/invoices ...  Static SPA (/)
         |           |            |           |      |
         v           v            v           v      v
    api-clients  api-payments  api-invoices   ...   /dist/index.html
```

| Ingress Route | Upstream Microservice | Internal Destination | Protocol |
|---|---|---|---|
| `/` | Frontend Static SPA | `/usr/share/nginx/html` | Static HTTP |
| `/api/clients/*` (or `/api/clientes/*`) | Customer Management | `http://api-clients:8080/clientes/*` | Internal HTTP |
| `/api/payments/*` (or `/api/pagos/*`) | Payment Processing | `http://api-payments:8080/pagos/*` | Internal HTTP |
| `/api/invoices/*` (or `/api/facturas/*`) | Invoicing & Billing | `http://api-invoices:8080/facturas/*` | Internal HTTP |
| `/api/transactions/*` (or `/api/transacciones/*`) | Financial Transactions | `http://api-transactions:8080/transacciones/*` | Internal HTTP |
| `/api/cards/*` (or `/api/tarjetas/*`) | Card Management | `http://api-cards:8080/tarjetas/*` | Internal HTTP |

---

## 🛠️ Multi-Stage Container Architecture

```
[ Stage 1: Build (Node.js 20 Alpine) ]
node:20-alpine
  -> npm ci (deterministic dependencies)
  -> npm run build (bundles production assets into dist/)

[ Stage 2: Production Gateway (NGINX Alpine) ]
nginx:alpine
  -> Installs OpenSSL for runtime TLS bootstrapping
  -> Copies dist/ static artifacts to /usr/share/nginx/html
  -> Mounts nginx/nginx.conf reverse proxy rules
  -> Executes entrypoint.sh: generates ephemeral TLS keys on container start
  -> Exposes port 443 ONLY (Port 80 disabled)
```

### Container Resource Governance
Configured via `docker-compose.yml`:
- **CPU Limit**: `0.25`
- **Memory Limit**: `128m`
- **Restart Policy**: `always`

---

## 💻 Local Development (Without Docker)

### Option A: Local Dev Server with Vite Proxy (Recommended)
Vite includes a built-in development proxy configured in `vite.config.js`. You can run the backend APIs locally on independent ports and point Vite to them:

```bash
cd web
npm install
npm run dev
```
Open `http://localhost:5173` in your browser.

### Option B: Local Production Simulation
```bash
cd web
npm install
npm run build    # Compiles assets into dist/
npm run preview  # Serves compiled bundle locally
```

---

## 🐳 Docker Build & Execution

```bash
# Build multi-stage image from repository root
docker build -t maxiescgit/web:1.0.1 -f web/Dockerfile .

# Run container mapping host port 443
docker run -d --name web \
  -p 443:443 \
  maxiescgit/web:1.0.1
```

> [!NOTE]
> Since certificates are generated on the fly upon boot, accept the self-signed certificate warning in your browser when connecting over `https://localhost` or the host IP.

---

## 📚 Related Documentation
- [Security & Hardening Specification](SECURITY.md)
- [Troubleshooting & Error Log](ERRORS.md)
