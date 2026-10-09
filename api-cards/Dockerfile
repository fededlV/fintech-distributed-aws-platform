FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY api-cards/ApiTarjetas.csproj api-cards/
RUN dotnet restore api-cards/ApiTarjetas.csproj

COPY api-cards/ api-cards/
RUN dotnet publish api-cards/ApiTarjetas.csproj \
    -c Release \
    -o /app/publish \
    /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*
WORKDIR /app

ENV PORT=8080
EXPOSE 8080

COPY --from=build /app/publish .

HEALTHCHECK --interval=10s --timeout=3s --retries=3 --start-period=15s \
  CMD curl -f http://localhost:8080/health/live || exit 1

USER $APP_UID
ENTRYPOINT ["dotnet", "ApiTarjetas.dll"]
