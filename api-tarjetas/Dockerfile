FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY api-tarjetas/ApiTarjetas.csproj api-tarjetas/
RUN dotnet restore api-tarjetas/ApiTarjetas.csproj

COPY api-tarjetas/ api-tarjetas/
RUN dotnet publish api-tarjetas/ApiTarjetas.csproj \
    -c Release \
    -o /app/publish \
    /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app

ENV PORT=8080
EXPOSE 8080

COPY --from=build /app/publish .

USER $APP_UID
ENTRYPOINT ["dotnet", "ApiTarjetas.dll"]
