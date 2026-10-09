# 🛡️ Security & Hardening Specification — `api-payments`

[![Security Standard](https://img.shields.io/badge/Security-Least%20Privilege-success)](README.md)
[![Runtime](https://img.shields.io/badge/Runtime-Node.js%20(Alpine)-339933)](README.md)

This document outlines the security controls, container isolation strategies, and attack surface reduction measures applied to the **Payment Processing Service** (`api-payments`).

---

## 🔒 Defensive Security Controls

### 1. Rootless Execution (`USER node`)
The official Node.js Docker image supplies a dedicated non-privileged system user (`node`, UID 1000). Running the runtime process under this account prevents an application compromise from gaining root namespace access on the host:
```dockerfile
WORKDIR /usr/src/app
RUN chown -R node:node /usr/src/app
USER node
```

### 2. Attack Surface Minimization (Alpine Linux)
`api-payments` is built on `node:20-alpine`. Alpine Linux provides a minimal, hardened footprint:
- Eliminates unnecessary system utilities, development compilers, and background services.
- Vastly reduces the common vulnerability and exposure (CVE) profile of the final container image compared to standard Debian/Ubuntu base images.

### 3. Production Dependency Sanitization
Development dependencies (test suites, linters, hot-reloaders) frequently introduce non-audited dependencies that expand the attack surface.
To ensure clean production images:
```dockerfile
ENV NODE_ENV=production
RUN npm ci --only=production
```
Using `npm ci` strictly honors `package-lock.json` checksums, guaranteeing immutable and deterministic builds.

### 4. Build Context Protection
A dedicated `.dockerignore` file prevents confidential assets from entering Docker build layers:
- Excludes `.env` files and local secrets.
- Excludes `.git` history and developer IDE metadata.
- Excludes local `node_modules/` to guarantee that only fresh, audited packages are installed inside the container environment.

---

## 🛡️ Threat Model & Mitigation Matrix

| Threat Vector | Risk Level | Applied Mitigation |
|---|---|---|
| **Remote Code Execution (RCE) via npm Package** | High | Unprivileged `USER node` restricts file writes and prevents host namespace escalation. |
| **Tampered Dependencies** | High | `npm ci` verifies package integrity hashes against `package-lock.json`. |
| **Credential Exposure in Docker Layers** | Critical | Secrets injected via Docker Compose `env_file`; excluded via `.dockerignore`. |
| **Memory / CPU Exhaustion Attacks** | Medium | Docker Compose imposes hard memory limits (`256m`) and CPU caps (`0.25`). |