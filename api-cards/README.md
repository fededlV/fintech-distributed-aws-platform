# 💳 Card Management Service (`api-cards`)

[![.NET](https://img.shields.io/badge/.NET-8.0%20(LTS)-512BD4?logo=dotnet&logoColor=white)](https://dotnet.microsoft.com/)
[![ASP.NET Core](https://img.shields.io/badge/ASP.NET%20Core-Minimal%20API-512BD4?logo=dotnet&logoColor=white)](https://learn.microsoft.com/aspnet/core/fundamentals/minimal-apis)
[![Docker](https://img.shields.io/badge/Docker-Multi--Stage%20Build-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![Security](https://img.shields.io/badge/Security-Non--Root%20($APP__UID)-success)](SECURITY.md)

The **Card Management Service** (`api-cards`) is a high-performance card account microservice engineered with **.NET 8 Minimal APIs** and raw SQL execution via `MySqlConnector` (bypassing heavyweight ORM overhead for maximum execution speed). It manages card metadata, cardholder profiles, card types, and credit limits inside the isolated `db_tarjetas` MariaDB schema.

> [!NOTE]
> **Data Privacy & Compliance**: In alignment with modern data protection principles, raw Primary Account Numbers (PANs) and CVVs are not ingested or stored. The service manages card tokens, aliases, cardholder names, card classifications, and spending thresholds.

---

## 🚀 API Specification & Endpoints

| HTTP Method | Route | Description | Auth / Scope |
|---|---|---|---|
| `GET` | `/` | Service health check | Internal |
| `GET` | `/tarjetas` | List all registered cards | Public / Gateway |
| `GET` | `/tarjetas/:id` | Retrieve single card profile by ID | Public / Gateway |
| `POST` | `/tarjetas` | Issue and register a new card | Public / Gateway |
| `PUT` | `/tarjetas/:id` | Update card alias, limit, or status | Public / Gateway |
| `DELETE` | `/tarjetas/:id` | Revoke / delete card record | Public / Gateway |

### Sample Payload (`POST` / `PUT`)
```json
{
  "alias": "Visa Gold Corporate",
  "titular": "Juan Perez",
  "tipo": "credito",
  "limite": 500000.00
}
```

---

## 🛠️ Multi-Stage Container Architecture

The service utilizes .NET 8 multi-stage build optimization to separate compilation dependencies from production runtimes:

```
[ Stage 1: Build & Publish (.NET 8 SDK) ]
mcr.microsoft.com/dotnet/sdk:8.0
  -> Restores ApiTarjetas.csproj dependencies
  -> Publishes compiled binary in Release configuration:
     dotnet publish -c Release -o /app/publish /p:UseAppHost=false

[ Stage 2: Production Runtime (ASP.NET 8 Core) ]
mcr.microsoft.com/dotnet/aspnet:8.0
  -> Minimal runtime footprint without the full SDK
  -> Runs under non-privileged system UID: USER $APP_UID
  -> Exposes port 8080
  -> ENTRYPOINT ["dotnet", "ApiTarjetas.dll"]
```

### Container Resource Governance
Configured via `docker-compose.yml`:
- **CPU Limit**: `0.25`
- **Memory Limit**: `256m`
- **Restart Policy**: `always`

---

## 💻 Local Development (Without Docker)

### Prerequisites
- .NET 8.0 SDK
- Accessible MariaDB / MySQL instance (with schema `db_tarjetas`)

```bash
cd api-cards

# 1. Configure environment variables
cp env.example .env
export $(grep -v '^#' .env | xargs)

# 2. Run the application
dotnet run
```

### Quick Verification
```bash
curl http://localhost:8080/tarjetas
```

---

## 🐳 Docker Build & Execution

```bash
# Build multi-stage image from repository root
docker build -t franlopezmora/api-tarjetas:1.0.0 -f api-cards/Dockerfile .

# Run container with external environment configuration
docker run --name api-cards \
  --env-file ../envs/api-cards.env \
  -p 8080:8080 \
  franlopezmora/api-tarjetas:1.0.0
```
