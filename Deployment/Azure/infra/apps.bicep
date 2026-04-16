/*
  AssociationManager - Container Apps Deployment (Bicep)
  This script creates the individual apps within the existing environment.
*/

param location string = resourceGroup().location
param environmentName string = 'qa'
param baseName string = 'assocmgr'
param containerAppEnvName string
param acrName string

@description('The version/tag of the images to deploy.')
param imageTag string = 'latest'

var uniqueSuffix = uniqueString(resourceGroup().id)
var envBaseName = '${baseName}-${environmentName}'
var acrLoginServer = '${acrName}.azurecr.io'

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
    }
  ]
  scale: {
    minReplicas: 0
    maxReplicas: 3
  }
}

// 1. Gateway (YARP)
resource gateway 'Microsoft.App/containerApps@2023-05-01' = {
  name: '${envBaseName}-gateway'
  location: location
  properties: {
    managedEnvironmentId: resourceId('Microsoft.App/managedEnvironments', containerAppEnvName)
    configuration: {
      ingress: {
        external: true
        targetPort: 8080
      }
      registries: [
        {
          server: acrLoginServer
          username: acrName
          passwordSecretRef: 'acr-password'
        }
      ]
      secrets: [
        {
          name: 'acr-password'
          value: 'REPLACE_ME_IN_CI_CD'
        }
      ]
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
          ]
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 3
      }
    }
  }
}

// 2. Association API
resource assocApi 'Microsoft.App/containerApps@2023-05-01' = {
  name: '${envBaseName}-api'
  location: location
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

// 4. Background Worker
resource worker 'Microsoft.App/containerApps@2023-05-01' = {
  name: '${envBaseName}-worker'
  location: location
  properties: {
    managedEnvironmentId: resourceId('Microsoft.App/managedEnvironments', containerAppEnvName)
    configuration: {
      ingress: null // Workers don't need ingress
    }
    template: defaultTemplate
  }
}
