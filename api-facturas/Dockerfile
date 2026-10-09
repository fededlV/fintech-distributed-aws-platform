# Stage 1: compilar con Maven
FROM maven:3.9-eclipse-temurin-21 AS build                                     
WORKDIR /app                                                                 
COPY api-facturas/pom.xml ./
RUN mvn dependency:resolve
COPY api-facturas/src ./src
RUN mvn package -DskipTests

# Stage 2: imagen final con solo el JRE
FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /app/target/api-facturas.jar .
EXPOSE 8080
CMD ["java", "-Xmx256m", "-jar", "api-facturas.jar"]