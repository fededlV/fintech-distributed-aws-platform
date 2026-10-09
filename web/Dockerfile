FROM node:20-alpine AS build
WORKDIR /app
COPY web/package*.json ./
RUN npm ci
COPY web/ .
RUN npm run build

FROM nginx:alpine
RUN apk add --no-cache openssl
COPY --from=build /app/dist /usr/share/nginx/html
COPY web/nginx/nginx.conf /etc/nginx/conf.d/default.conf
COPY web/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
EXPOSE 443

HEALTHCHECK --interval=10s --timeout=3s --retries=3 --start-period=5s \
  CMD wget --no-check-certificate -q --spider https://127.0.0.1:443/healthz || exit 1

CMD ["/entrypoint.sh"]
