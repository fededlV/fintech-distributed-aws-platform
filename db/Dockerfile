FROM mariadb:11.8.9-ubi9

USER 0

COPY db/init-scripts/ /docker-entrypoint-initdb.d/

RUN sed -i 's/\r$//' /docker-entrypoint-initdb.d/*.sh \
    && chmod +x /docker-entrypoint-initdb.d/*.sh

USER mysql
