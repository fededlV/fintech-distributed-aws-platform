FROM mariadb:11.8.9-ubi9

USER 0

COPY db/init-scripts/ /docker-entrypoint-initdb.d/

RUN sed -i 's/\r$//' /docker-entrypoint-initdb.d/*.sh \
    && chmod +x /docker-entrypoint-initdb.d/*.sh

USER mysql

HEALTHCHECK --interval=5s --timeout=3s --retries=10 --start-period=15s \
  CMD mariadb-admin ping -h 127.0.0.1 --silent || exit 1
