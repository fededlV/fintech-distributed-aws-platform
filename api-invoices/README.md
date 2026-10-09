# 🧾 Invoicing & Billing Service (`api-invoices`)

[![Java](https://img.shields.io/badge/Java-21%20(LTS)-ED8B00?logo=openjdk&logoColor=white)](https://openjdk.org/)
[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.x-6DB33F?logo=springboot&logoColor=white)](https://spring.io/projects/spring-boot)
[![Docker](https://img.shields.io/badge/Docker-Multi--Stage%20(Temurin%20JRE)-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![Security](https://img.shields.io/badge/Security-Hardened%20JVM-success)](SECURITY.md)

The **Invoicing & Billing Service** (`api-invoices`) provides billing record management, tax calculations, and invoice lifecycle operations for the **FinTech Nova** platform. Built with Java 21 and Spring Boot, it persists billing entities to the isolated `db_facturas` MariaDB schema.

---

## 🚀 API Specification & Endpoints

| HTTP Method | Route | Description | Auth / Scope |
|---|---|---|---|
| `GET` | `/facturas` | List all invoices | Public / Gateway |
| `GET` | `/facturas/:id` | Retrieve invoice details by ID | Public / Gateway |
| `POST` | `/facturas` | Generate and persist new invoice | Public / Gateway |
| `PUT` | `/facturas/:id` | Update invoice metadata | Public / Gateway |
| `DELETE` | `/facturas/:id` | Cancel / delete invoice record | Public / Gateway |

### Sample Payload (`POST` / `PUT`)
```json
{
  "numero": "A-0003",
  "monto": 12000.50,
  "clienteId": 1,
  "fechaEmision": "2026-03-01"
}
```

---

## 🛠️ Multi-Stage Container Architecture

To minimize container size and eliminate compilation toolchains from the production environment, the image uses an optimized **multi-stage build**:

```
[ Stage 1: Build (Maven + JDK 21) ]
maven:3.9-eclipse-temurin-21
  -> Copies pom.xml and resolves dependencies (cached)
  -> Copies src/ and compiles via: mvn package -DskipTests
  -> Produces standalone Spring Boot fat JAR: api-facturas.jar

[ Stage 2: Runtime (Slim JRE 21) ]
eclipse-temurin:21-jre
  -> Discards Maven, compiler tools, source code, and cache (~700MB)
  -> Copies ONLY api-facturas.jar into lightweight JRE (~270MB)
  -> Enforces JVM heap boundaries (-Xmx256m)
```

### Container Resource Governance
Configured in `docker-compose.yml`:
- **CPU Limit**: `0.50`
- **Memory Limit**: `512m` (with JVM heap constrained to `-Xmx256m`)
- **Restart Policy**: `always`

---

## 💻 Local Development (Without Docker)

### Prerequisites
- JDK 21+
- Apache Maven 3.9+
- Accessible MariaDB/MySQL instance

```bash
cd api-invoices

# 1. Configure environment
cp env.example .env
export $(grep -v '^#' .env | xargs)

# 2. Run with Spring Boot Maven plugin
mvn spring-boot:run
```

### Quick Verification
```bash
curl http://localhost:8080/facturas
```

---

## 🐳 Docker Build & Execution

```bash
# Build multi-stage image from root context
docker build -t maxiescgit/api-facturas:1.0.0 -f api-invoices/Dockerfile .

# Run container with environment configuration
docker run --name api-invoices \
  --env-file ../envs/api-invoices.env \
  -p 8080:8080 \
  maxiescgit/api-facturas:1.0.0
```

---

## 📚 Related Documentation
- [Security & Hardening Specification](SECURITY.md)
- [Troubleshooting & Error Log](ERRORS.md)
