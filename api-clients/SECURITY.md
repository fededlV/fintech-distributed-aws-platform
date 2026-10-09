# 🛡️ Security & Hardening Specification — `api-clients`

[![Security Standard](https://img.shields.io/badge/Security-Least%20Privilege-success)](README.md)
[![Runtime](https://img.shields.io/badge/Runtime-Rootless%20Python-3776AB)](README.md)

This document details the defensive controls, threat mitigations, and container hardening policies implemented for the **Customer Management Service** (`api-clients`).

---

## 🔒 Defensive Security Controls

### 1. Principle of Least Privilege: Rootless Container Execution
By default, Docker executes container processes as UID 0 (`root`). In the event of a remote code execution (RCE) vulnerability within the Flask web framework or an upstream dependency, a root process significantly lowers the barrier for **container escape** onto the host operating system.

To mitigate this attack vector:
1. A dedicated non-privileged user and group (`appuser`) is provisioned:
   ```dockerfile
   RUN adduser --disabled-password --gecos '' appuser
   ```
2. Application source code and dependencies are restricted to this non-root user:
   ```dockerfile
   RUN chown -R appuser:appuser /app
   USER appuser
   ```
3. The process runs without `sudo` privileges and cannot modify root-owned system directories or interact with the host socket.

### 2. Multi-Stage Virtual Environment Isolation
Instead of installing Python packages directly into global system paths (`/usr/local`), dependencies are installed inside an isolated virtual environment (`/opt/venv`) during the builder phase:
- Compiler tooling, temporary build artifacts, and pip caches are discarded in the builder stage (`--no-cache-dir`).
- The runtime image inherits only the sanitized `/opt/venv` directory with strict ownership assigned to `appuser`.

### 3. Build Context Protection & Zero Secrets in Version Control
- All sensitive credentials (`DB_USER`, `DB_PASSWORD`, `DB_HOST`) are injected at runtime via Docker Compose `env_file` directives.
- `.dockerignore` prevents accidental inclusion of local virtual environments (`venv/`), `.git` repositories, `.env` files, and IDE metadata into Docker layers.
- Python runtime flags are enforced:
  - `PYTHONDONTWRITEBYTECODE=1`: Prevents writing ephemeral `.pyc` files to disk.
  - `PYTHONUNBUFFERED=1`: Ensures application logs flush immediately to stdout/stderr for container logging collectors.

---

## 🛡️ Threat Model & Mitigation Matrix

| Threat / Attack Vector | Risk Level | Mitigation Strategy |
|---|---|---|
| **Container Breakout via RCE** | High | Non-root `appuser` execution eliminates root namespace access on the host. |
| **Credential Leakage in Registries** | Critical | Secrets injected strictly at runtime via `.env`; excluded from Dockerfile and build context. |
| **Noisy Neighbor Resource Starvation** | Medium | Docker Compose assigns strict resource limits (`cpus: 0.25`, `memory: 256m`). |
| **Vulnerable Build Dependencies** | Medium | Multi-stage build discards compilation toolchains and caching layers from the final image. |