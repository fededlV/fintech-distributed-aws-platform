# 👥 Customer Management Service (`api-clients`)

[![Python](https://img.shields.io/badge/Python-3.11-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![Flask](https://img.shields.io/badge/Flask-3.0-000000?logo=flask&logoColor=white)](https://flask.palletsprojects.com/)
[![Docker](https://img.shields.io/badge/Docker-Multi--Stage%20Build-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![Security](https://img.shields.io/badge/Security-Non--Root%20(appuser)-success)](SECURITY.md)

The **Customer Management Service** (`api-clients`) is a core domain microservice within the **FinTech Nova** platform, responsible for customer onboarding, identity records (DNI/Tax ID), and profile maintenance. It persists data to the dedicated `db_clientes` schema hosted on MariaDB.

---

## 🚀 API Specification & Endpoints

| HTTP Method | Route | Description | Auth / Scope |
|---|---|---|---|
| `GET` | `/` | Service health check | Internal |
| `GET` | `/clientes` | List all customer profiles | Public / Gateway |
| `GET` | `/clientes/:id` | Retrieve customer profile by ID | Public / Gateway |
| `POST` | `/clientes` | Register a new customer | Public / Gateway |
| `PUT` | `/clientes/:id` | Update existing customer details | Public / Gateway |
| `DELETE` | `/clientes/:id` | Delete customer profile | Public / Gateway |

### Sample Payload (`POST` / `PUT`)
```json
{
  "nombre": "Ana Torres",
  "email": "ana.torres@example.com",
  "dni": "30111222"
}
```

---

## 🛠️ Architecture & Containerization

The service implements a hardened **multi-stage Docker build** targeting minimum runtime footprint and defense-in-depth security:

```
[ Stage 1: Builder ]
python:3.11-slim
  -> Creates isolated virtual environment (/opt/venv)
  -> Compiles wheels & installs requirements.txt without pip cache

[ Stage 2: Runner ]
python:3.11-slim
  -> Creates non-root system user 'appuser'
  -> Copies ONLY /opt/venv from Builder stage
  -> Sets ENV PATH="/opt/venv/bin:$PATH"
  -> Drops all superuser privileges (USER appuser)
  -> Exposes port 8080 and launches main.py
```

### Container Resource Governance
Configured via `docker-compose.yml`:
- **CPU Limit**: `0.25`
- **Memory Limit**: `256m`
- **Restart Policy**: `always`

---

## 💻 Local Development (Without Docker)

### Prerequisites
- Python 3.11+
- Running MariaDB / MySQL instance (with schema `db_clientes`)

```bash
cd api-clientes

# 1. Create and activate virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# 2. Install dependencies
pip install -r requirements.txt

# 3. Configure environment variables
cp env.example .env
# Set DB_HOST=localhost, DB_PORT=3306, DB_USER, DB_PASSWORD, DB_NAME=db_clientes

# 4. Export variables and start server
export $(grep -v '^#' .env | xargs)
python main.py
```

### Quick Verification
```bash
curl http://localhost:8080/clientes
```

---

## 🐳 Docker Build & Manual Execution

```bash
# Build multi-stage image
docker build -t fededlv/api-clientes:1.0.0 .

# Run isolated container with environment file
docker run --name api-clientes \
  --env-file ../envs/api-clientes.env \
  -p 8080:8080 \
  fededlv/api-clientes:1.0.0
```

---

## 📚 Related Documentation
- [Security & Hardening Specification](SECURITY.md)
- [Troubleshooting & Error Log](ERRORS.md)
