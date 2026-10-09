# 🛡️ Security & Hardening Specification — `api-invoices`

[![Security Standard](https://img.shields.io/badge/Security-Hardened%20JVM-success)](README.md)
[![Runtime](https://img.shields.io/badge/Runtime-Temurin%20JRE%2021-ED8B00)](README.md)

This document outlines the defensive controls, memory boundaries, and container hardening policies implemented for the **Invoicing & Billing Service** (`api-invoices`).

---

## 🔒 Defensive Security Controls

### 1. Minimal JRE Runtime Footprint
`api-invoices` is packaged using the official **Eclipse Temurin 21 JRE** (`eclipse-temurin:21-jre`).
- Unlike standard JDK development images, the JRE runtime strips compilers (`javac`), source debugging tools, header files, and administrative utilities.
- Eliminates unnecessary packages to substantially lower the container's Common Vulnerabilities and Exposures (CVE) exposure.

### 2. Multi-Stage Pipeline Isolation
The build environment (`maven:3.9-eclipse-temurin-21`) contains Maven plugins, project object models, and local caching repositories (`~/.m2`).
- The multi-stage build discards the entire build environment after compilation.
- Only the sanitized binary `api-facturas.jar` is copied into the final runtime container, preventing source code exposure and build-tool weaponization.

### 3. Memory & Resource Safeguards
Java applications can aggressively consume memory if unconstrained:
- The container command enforces JVM heap bounds via `-Xmx256m`.
- The container is governed by Docker Compose with a hard limit of `memory: 512m` and `cpus: "0.5"`.
- This ensures the JVM process cannot induce host Out-Of-Memory (OOM) kernel panics or degrade adjacent microservices.

### 4. Secret Isolation
Database credentials (`DB_USER`, `DB_PASSWORD`) and network hosts are injected exclusively via external environment files (`envs/api-invoices.env`).
- Credentials are never hardcoded in `pom.xml`, source files, or `Dockerfile`.
- Files are protected via `.gitignore` and delivered through secure SCP channels.

---

## 🛡️ Threat Model & Mitigation Matrix

| Threat Vector | Risk Level | Mitigation Strategy |
|---|---|---|
| **Compilation Tool Weaponization** | Medium | Multi-stage build strips Maven and the JDK; only the JRE runs in production. |
| **JVM Memory Exhaustion (OOM)** | High | `-Xmx256m` heap cap combined with Docker cgroup memory limit (`512m`). |
| **Credential Exposure** | Critical | External `.env` runtime injection; zero secrets stored in container registry layers. |
| **Database Connection Hijacking** | Medium | Isolated credentials targeting solely the `db_facturas` database schema. |
