# Build Stage
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy all project files to restore dependencies
COPY ["AssociationManager.Worker/AssociationManager.Worker.csproj", "AssociationManager.Worker/"]
COPY ["AssociationManager.Auth/AssociationManager.Auth.csproj", "AssociationManager.Auth/"]
COPY ["AssociationManager.Data/AssociationManager.Data.csproj", "AssociationManager.Data/"]
COPY ["AssociationManager.Services/AssociationManager.Services.csproj", "AssociationManager.Services/"]
COPY ["AssociationManager.Shared/AssociationManager.Shared.csproj", "AssociationManager.Shared/"]

RUN dotnet restore "AssociationManager.Worker/AssociationManager.Worker.csproj"

# Copy everything and build
COPY . .
WORKDIR "/src/AssociationManager.Worker"
RUN dotnet publish "AssociationManager.Worker.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Runtime Stage
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "AssociationManager.Worker.dll"]
