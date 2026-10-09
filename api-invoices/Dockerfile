# Stage 1: compilar con Maven
FROM maven:3.9-eclipse-temurin-21 AS build                                     
WORKDIR /app                                                                 
COPY api-invoices/pom.xml ./
RUN mvn dependency:resolve
COPY api-invoices/src ./src
RUN mvn package -DskipTests

# Stage 2: imagen final con solo el JRE
FROM eclipse-temurin:21-jre
RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=build /app/target/api-facturas.jar .
EXPOSE 8080

HEALTHCHECK --interval=10s --timeout=3s --retries=5 --start-period=45s \
  CMD curl -f http://localhost:8080/health/live || exit 1

CMD ["java", "-Xmx256m", "-jar", "api-facturas.jar"]