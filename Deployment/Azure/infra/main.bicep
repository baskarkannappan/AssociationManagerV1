/*
  AssociationManager - Main Infrastructure Deployment (Bicep)
  This script provisions the environment for the QA/Testing cluster.
*/

@description('The location for all resources. Default is East US for cost efficiency.')
param location string = resourceGroup().location

@description('The name of the environment (e.g., qa, dev, prod).')
param environmentName string = 'qa'

@description('The base name for the application.')
param baseName string = 'assocmgr'

@description('The administrator login for the SQL Server.')
param administratorLogin string

@description('The administrator login password for the SQL Server.')
@secure()
param administratorLoginPassword string

var uniqueSuffix = uniqueString(resourceGroup().id)
var envBaseName = '${baseName}-${environmentName}'

// 1. Log Analytics Workspace (Required for Container Apps monitoring)
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: '${envBaseName}-logs-${uniqueSuffix}'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// 2. Azure Container Registry (To store your Docker images)
resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: replace('${envBaseName}acr${uniqueSuffix}', '-', '')
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
}

// 3. Azure Container Apps Environment
resource containerAppEnv 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: '${envBaseName}-env-${uniqueSuffix}'
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
  }
}

// 4. Azure SQL Database (Serverless)
resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: '${envBaseName}-sql-srv-${uniqueSuffix}'
  location: location
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
  }
}

resource sqlDB 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  parent: sqlServer
  name: '${envBaseName}-db'
  location: location
  sku: {
    name: 'GP_S_Gen5_1' // General Purpose, Serverless, Gen 5, 1 vCore
    tier: 'GeneralPurpose'
    family: 'Gen5'
    capacity: 1
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 2147483648 // 2GB
    autoPauseDelay: 60 // Auto-pause after 1 hour of inactivity
    minCapacity: any('0.5')
  }
}

// 5. Azure Key Vault (For Secrets Management)
resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: 'kv-${uniqueSuffix}'
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    accessPolicies: []
  }
}

// 6. Azure Static Web Apps (Frontends)
resource assocClient 'Microsoft.Web/staticSites@2022-09-01' = {
  name: '${envBaseName}-assoc-client-${uniqueSuffix}'
  location: 'eastus2' // SWAs are available in specific regions
  sku: {
    name: 'Free'
    tier: 'Free'
  }
  properties: {}
}

resource corpClient 'Microsoft.Web/staticSites@2022-09-01' = {
  name: '${envBaseName}-corp-client-${uniqueSuffix}'
  location: 'eastus2'
  sku: {
    name: 'Free'
    tier: 'Free'
  }
  properties: {}
}

output acrLoginServer string = acr.properties.loginServer
output acrName string = acr.name
output envName string = containerAppEnv.name
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
output sqlDbName string = sqlDB.name
output kvName string = keyVault.name
