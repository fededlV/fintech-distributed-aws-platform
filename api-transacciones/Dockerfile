# Stage1: compilar
FROM golang:1.22 AS build
WORKDIR /app
COPY api-transacciones/go.mod api-transacciones/go.sum ./
RUN go mod download
COPY api-transacciones/ .
RUN CGO_ENABLED=0 go build -o api-transacciones .

# Stage 2: imagen final minima
FROM alpine 
WORKDIR /app
COPY --from=build /app/api-transacciones .
EXPOSE 8080
CMD ["./api-transacciones"]