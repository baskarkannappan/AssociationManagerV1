/*
  AssociationManager - Container Apps Deployment (Bicep)
  This script creates the individual apps within the existing environment.
*/

param location string = resourceGroup().location
param environmentName string = 'qa'
param baseName string = 'assocmgr'
param containerAppEnvName string
var uniqueSuffix = uniqueString(resourceGroup().id)
var envBaseName = '${baseName}-${environmentName}'

// Service-to-Service URLs (Internal)
var gatewayUrl = 'https://${envBaseName}-gateway.${uniqueSuffix}.internal'
var apiUrl = 'https://${envBaseName}-api.${uniqueSuffix}.internal'
var corporateApiUrl = 'https://${envBaseName}-corp-api.${uniqueSuffix}.internal'

// Shared Template for consumption-based apps
var defaultTemplate = {
  containers: [
    {
      name: 'main'
      image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest' // Placeholder until CI/CD pushes
      resources: {
        cpu: json('0.25')
        memory: '0.5Gi'
      }
      env: [
        {
          name: 'AllowedOrigins'
          value: 'https://happy-tree-0a717950f.7.azurestaticapps.net,https://lemon-coast-03635380f.7.azurestaticapps.net'
        }
        {
          name: 'KeyVaultName'
          value: 'kv-assocmgr-dev-unique'
        }
      ]
    }
  ]
  scale: {
    minReplicas: 0
    maxReplicas: 1
  }
}

// 1. Gateway (YARP)
resource gateway 'Microsoft.App/containerApps@2023-05-01' = {
  name: '${envBaseName}-gateway'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: resourceId('Microsoft.App/managedEnvironments', containerAppEnvName)
    configuration: {
      ingress: {
        external: true
        targetPort: 8080
      }
    }
    template: {
      containers: [
        {
          name: 'main'
          image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
          resources: {
            cpu: json('0.25')
            memory: '0.5Gi'
          }
          env: [
            {
              name: 'ReverseProxy__Clusters__api-cluster__Destinations__destination1__Address'
              value: apiUrl
            }
            {
              name: 'ReverseProxy__Clusters__corporate-api-cluster__Destinations__destination1__Address'
              value: corporateApiUrl
            }
            {
              name: 'KeyVaultName'
              value: 'kv-assocmgr-dev-unique'
            }
          ]
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 1
      }
    }
  }
}

// 2. Association API
resource assocApi 'Microsoft.App/containerApps@2023-05-01' = {
  name: '${envBaseName}-api'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: resourceId('Microsoft.App/managedEnvironments', containerAppEnvName)
    configuration: {
      ingress: {
        external: true
        targetPort: 8080
      }
    }
    template: defaultTemplate
  }
}

// 3. Corporate API
resource corpApi 'Microsoft.App/containerApps@2023-05-01' = {
  name: '${envBaseName}-corp-api'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: resourceId('Microsoft.App/managedEnvironments', containerAppEnvName)
    configuration: {
      ingress: {
        external: true
        targetPort: 8080
      }
    }
    template: defaultTemplate
  }
}

// Role Assignments for Key Vault
resource kv 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: 'kv-assocmgr-dev-unique'
}

resource kvRoleGateway 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(gateway.id, kv.id, 'KeyVaultSecretsUser')
  scope: kv
  properties: {
    principalId: gateway.identity.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '46334583-0161-460d-9669-7c413b5a153f') // Key Vault Secrets User
    principalType: 'ServicePrincipal'
  }
}

resource kvRoleAssocApi 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(assocApi.id, kv.id, 'KeyVaultSecretsUser')
  scope: kv
  properties: {
    principalId: assocApi.identity.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '46334583-0161-460d-9669-7c413b5a153f')
    principalType: 'ServicePrincipal'
  }
}

resource kvRoleCorpApi 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(corpApi.id, kv.id, 'KeyVaultSecretsUser')
  scope: kv
  properties: {
    principalId: corpApi.identity.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '46334583-0161-460d-9669-7c413b5a153f')
    principalType: 'ServicePrincipal'
  }
}

