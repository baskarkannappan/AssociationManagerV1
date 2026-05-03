# Build Stage
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy csproj files and restore as distinct layers
COPY ["AssociationManager.Gateway/AssociationManager.Gateway.csproj", "AssociationManager.Gateway/"]
COPY ["AssociationManager.Shared/AssociationManager.Shared.csproj", "AssociationManager.Shared/"]

RUN dotnet restore "AssociationManager.Gateway/AssociationManager.Gateway.csproj"

# Copy everything else and build app
COPY . .
WORKDIR "/src/AssociationManager.Gateway"
RUN dotnet publish "AssociationManager.Gateway.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Runtime Stage
FROM mcr.microsoft.com/dotnet/aspnet:9.0-bookworm-slim AS final
WORKDIR /app
EXPOSE 8080
EXPOSE 8081
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "AssociationManager.Gateway.dll"]
