# 🛠️ Troubleshooting & Incident Runbook — `web`

[![Component](https://img.shields.io/badge/Gateway-NGINX%20Frontend-009639)](README.md)
[![Status](https://img.shields.io/badge/Runbook-Operational-success)](README.md)

This runbook documents reverse proxy misconfigurations, TLS handshake anomalies, and asset pipeline errors encountered during the implementation and deployment of the **Web Gateway & Frontend Application** (`web`).

---

## 📋 Issue Log & Solutions

### 1. HTTP 502 Bad Gateway on Microservice Reverse Proxy Routes
* **Symptom**: The SPA frontend loads successfully, but all API requests (`/api/clientes`, `/api/pagos`, etc.) return `502 Bad Gateway`.
* **Root Cause**: Upstream service hostnames configured inside `nginx/nginx.conf` did not match the exact service identifiers declared in `docker-compose.yml`. Docker's internal DNS resolver (`127.0.0.11`) could not resolve the upstream targets.
* **Resolution**:
  Aligned the upstream identifiers in `nginx.conf` with the compose service definitions:
  ```nginx
  location ~ ^/api/(clientes|clients) {
      set $upstream api-clients:8080;
      rewrite ^/api/(?:clientes|clients)(.*)$ /clientes$1 break;
      proxy_pass http://$upstream;
      proxy_set_header Host $host;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  }
  ```

---

### 2. Browser TLS Protocol Failure (`ERR_SSL_PROTOCOL_ERROR`)
* **Symptom**: Web browsers reject HTTPS handshakes with an SSL protocol error rather than displaying the expected untrusted self-signed certificate warning.
* **Root Cause**: NGINX started before the OpenSSL key generation subshell in `entrypoint.sh` had finished writing `cert.pem` and `key.pem` to `/etc/nginx/ssl/`, causing NGINX to bind without valid SSL context.
* **Resolution**:
  Added configuration and file validation before delegating to the NGINX foreground daemon:
  ```sh
  nginx -t && exec nginx -g 'daemon off;'
  ```
  `nginx -t` validates that certificate paths exist and syntax is valid before spawning worker threads.

---

### 3. Build Failure during `npm ci` (`package-lock.json` Missing)
* **Symptom**: Docker multi-stage build fails on Step 4 with `npm ci can only install packages when your package.json and package-lock.json or npm-shrinkwrap.json are in sync`.
* **Root Cause**: `package-lock.json` was absent or out of date in version control.
* **Resolution**:
  Executed `npm install` locally to synchronize lockfile hashes, committed `package-lock.json`, and re-ran the Docker build.

---

### 4. Static Asset 404 Not Found on Root Route (`/`)
* **Symptom**: Container runs and returns HTTP 200 on port 443, but displays a default 404 Not Found error.
* **Root Cause**: The `COPY --from=build` instruction in `Dockerfile` referenced an incorrect build output directory rather than Vite's default `dist/` folder.
* **Resolution**:
  Standardized the copy directive to NGINX's default document root:
  ```dockerfile
  COPY --from=build /app/dist /usr/share/nginx/html
  ```
