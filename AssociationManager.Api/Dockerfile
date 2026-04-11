# Build Stage
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy all project files to restore dependencies
COPY ["AssociationManager.Api/AssociationManager.Api.csproj", "AssociationManager.Api/"]
COPY ["AssociationManager.Auth/AssociationManager.Auth.csproj", "AssociationManager.Auth/"]
COPY ["AssociationManager.Data/AssociationManager.Data.csproj", "AssociationManager.Data/"]
COPY ["AssociationManager.Realtime/AssociationManager.Realtime.csproj", "AssociationManager.Realtime/"]
COPY ["AssociationManager.Services/AssociationManager.Services.csproj", "AssociationManager.Services/"]
COPY ["AssociationManager.Shared/AssociationManager.Shared.csproj", "AssociationManager.Shared/"]

RUN dotnet restore "AssociationManager.Api/AssociationManager.Api.csproj"

# Copy everything and build
COPY . .
WORKDIR "/src/AssociationManager.Api"
RUN dotnet publish "AssociationManager.Api.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Runtime Stage
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS final
WORKDIR /app
EXPOSE 8080
EXPOSE 8081
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "AssociationManager.Api.dll"]
