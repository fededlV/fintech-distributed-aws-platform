# Stage1: compilar
FROM golang:1.22 AS build
WORKDIR /app
COPY api-transactions/go.mod api-transactions/go.sum ./
RUN go mod download
COPY api-transactions/ .
RUN CGO_ENABLED=0 go build -o api-transactions .

# Stage 2: imagen final minima
FROM alpine 
WORKDIR /app
COPY --from=build /app/api-transactions .
EXPOSE 8080

HEALTHCHECK --interval=10s --timeout=3s --retries=3 --start-period=10s \
  CMD wget -q --spider http://localhost:8080/health/live || exit 1

CMD ["./api-transactions"]