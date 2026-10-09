# 🛡️ Security & Hardening Specification — `api-cards`

[![Security Standard](https://img.shields.io/badge/Security-Data%20Privacy%20%26%20Non--Root-success)](README.md)
[![Runtime](https://img.shields.io/badge/Runtime-.NET%208%20ASP.NET%20Core-512BD4)](README.md)

This document details the data privacy boundaries, non-root user execution, and container hardening controls implemented for the **Card Management Service** (`api-cards`).

---

## 🔒 Defensive Security Controls

### 1. Data Privacy & Zero-PAN Tokenization Model
Financial applications handling card payment instruments must adhere to strict PCI-DSS standards.
To avoid storing sensitive cardholder data:
- Primary Account Numbers (PANs), CVVs, and magnetic stripe data are **strictly forbidden** from entering this service database.
- The service persists only non-sensitive tokens, friendly aliases (e.g., `"Visa Gold Corporate"`), cardholder legal names, card types (`credito` / `debito`), and approved credit limits.

### 2. Built-in Non-Root Container Execution (`USER $APP_UID`)
Starting in .NET 8, official Microsoft ASP.NET Core container images include a dedicated non-root user mapped to `$APP_UID` (UID 1654):
```dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app
COPY --from=build /app/publish .
USER $APP_UID
ENTRYPOINT ["dotnet", "ApiTarjetas.dll"]
```
This guarantees that even if a zero-day vulnerability in the web server or serialization engine were triggered, the process cannot escalate privileges or manipulate system files on the host.

### 3. Attack Surface Minimization (Multi-Stage SDK Discard)
- The compilation stage (`mcr.microsoft.com/dotnet/sdk:8.0`) contains the .NET compiler, NuGet package caches, MSBuild utilities, and project files (~800MB).
- Only the compiled binaries produced by `dotnet publish -c Release /p:UseAppHost=false` are copied into the lean `aspnet:8.0` runtime image (~210MB).
- The final production image excludes all development tooling, source code, and SDK binaries.

### 4. Secret Isolation
Database credentials (`DB_USER`, `DB_PASSWORD`, `DB_HOST`, `DB_NAME`) are injected at runtime via Docker Compose `env_file` directives (`envs/api-cards.env`):
- All secrets are excluded from version control via `.gitignore`.
- Files are synchronized to the AWS EC2 instance through encrypted SCP channels.

---

## 🛡️ Threat Model & Mitigation Matrix

| Threat Vector | Risk Level | Mitigation Strategy |
|---|---|---|
| **PCI-DSS Scope Creep / Data Breach** | Critical | Strict architectural data contract: zero raw PAN/CVV storage. |
| **Container Breakout via RCE** | High | Non-root `USER $APP_UID` drops all superuser capabilities. |
| **Toolchain Weaponization** | Medium | Multi-stage build discards the .NET SDK from the runtime image. |
| **Noisy Neighbor Resource Contention** | Medium | Docker Compose defines hard memory caps (`256m`) and CPU quotas (`0.25`). |
