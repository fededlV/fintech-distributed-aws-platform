# 🛡️ Security & Hardening Specification — `api-transactions`

[![Security Standard](https://img.shields.io/badge/Security-Static%20Binary%20Hardening-success)](README.md)
[![Runtime](https://img.shields.io/badge/Runtime-Alpine%20Linux-0D597F)](README.md)

This document details the container hardening, attack surface reduction, and static compilation security controls applied to the **Financial Transactions Service** (`api-transactions`).

---

## 🔒 Defensive Security Controls

### 1. Static Binary Compilation (`CGO_ENABLED=0`)
By default, the Go compiler may dynamically link against system C libraries (`glibc`). Dynamic linking introduces external binary dependencies and runtime attack surface.
- The service enforces `CGO_ENABLED=0` to create a fully **statically linked binary**.
- The executable contains zero dependencies on shared host libraries (`libc`, `glibc`, or `musl`), allowing it to run securely inside a minimal Alpine container without compatibility conflicts.

### 2. Multi-Stage Build & Minimal Attack Surface
The builder stage (`golang:1.22`) contains the entire Go compiler suite, module cache, Git utilities, and application source code (~800MB).
- The final production stage uses `alpine:latest` and inherits solely the compiled `api-transactions` binary (~15MB total container footprint).
- Build tools, intermediate caches, and source files are completely excluded from production registries and production runtime environments.

### 3. Anonymous External Integrations & Non-Blocking Design
- The external geolocation API integration requires no API keys or static credentials, eliminating secret leak risks.
- Timeouts and non-blocking exception handlers in `geolocation.go` guarantee that network degradation or DNS failures on external providers cannot cause denial of service (DoS) or transaction rollbacks on internal financial ledgers.

### 4. Secret Isolation
Database credentials (`DB_USER`, `DB_PASSWORD`, `DB_HOST`, `DB_NAME`) are injected at runtime via Docker Compose `env_file` directives (`envs/api-transactions.env`):
- No database credentials are committed to version control.
- Isolated environment files are distributed to the cloud host through encrypted SCP channels.

---

## 🛡️ Threat Model & Mitigation Matrix

| Threat Vector | Risk Level | Mitigation Strategy |
|---|---|---|
| **Shared Library Exploitation** | High | `CGO_ENABLED=0` produces an immutable, statically linked binary. |
| **Compiler Toolchain Weaponization** | Medium | Multi-stage build discards the Go compiler; production image contains only the binary. |
| **External API Cascading Failure** | High | Non-blocking error handling prevents external API rate limits or outages from interrupting ledger writes. |
| **Container Memory Starvation** | Medium | Docker Compose assigns strict resource limits (`cpus: 0.25`, `memory: 128m`). |
