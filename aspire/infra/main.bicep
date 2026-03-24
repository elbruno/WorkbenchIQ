// =============================================================================
// WorkbenchIQ Azure Container Apps Infrastructure
// =============================================================================
// This is a STARTER TEMPLATE for Azure Container Apps deployment.
// TODO: Production hardening required before deploying to production.
//
// Production TODOs:
// - [ ] Add Azure Key Vault for secrets management
// - [ ] Configure managed identities for Azure service authentication
// - [ ] Add Application Insights for monitoring and diagnostics
// - [ ] Configure custom domains and SSL certificates
// - [ ] Add VNET integration for private networking
// - [ ] Configure scaling rules and resource limits
// - [ ] Add Azure Storage Account for persistent data
// - [ ] Configure PostgreSQL for production workloads
// - [ ] Add Azure CDN for static asset distribution
// - [ ] Configure backup and disaster recovery
// =============================================================================

@description('Primary location for all resources')
param location string = resourceGroup().location

@description('Environment name (e.g., dev, staging, prod)')
param environmentName string = 'dev'

@description('Backend container image')
param backendImage string = 'workbenchiq-backend:latest'

@description('Frontend container image')
param frontendImage string = 'workbenchiq-frontend:latest'

// =============================================================================
// Container Registry
// =============================================================================
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: 'cr${uniqueString(resourceGroup().id)}'
  location: location
  sku: {
    name: 'Basic'  // TODO: Upgrade to Standard or Premium for production
  }
  properties: {
    adminUserEnabled: true  // TODO: Use managed identity instead
  }
}

// =============================================================================
// Container Apps Environment
// =============================================================================
resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: 'cae-workbenchiq-${environmentName}'
  location: location
  properties: {
    // TODO: Add Application Insights workspace ID
    // appLogsConfiguration: {
    //   destination: 'log-analytics'
    //   logAnalyticsConfiguration: {
    //     customerId: logAnalyticsWorkspace.properties.customerId
    //     sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
    //   }
    // }
    // TODO: Add VNET configuration for private networking
  }
}

// =============================================================================
// Backend API Container App
// =============================================================================
resource backendApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: 'ca-backend-${environmentName}'
  location: location
  properties: {
    managedEnvironmentId: containerAppEnvironment.id
    configuration: {
      ingress: {
        external: true
        targetPort: 8000
        transport: 'http'
        // TODO: Configure custom domain and SSL
      }
      registries: [
        {
          server: containerRegistry.properties.loginServer
          username: containerRegistry.listCredentials().username
          passwordSecretRef: 'registry-password'
        }
      ]
      secrets: [
        {
          name: 'registry-password'
          value: containerRegistry.listCredentials().passwords[0].value
        }
        // TODO: Add Azure service secrets from Key Vault
        // - AZURE_OPENAI_API_KEY
        // - AZURE_CONTENT_UNDERSTANDING_API_KEY
        // - AZURE_STORAGE_ACCOUNT_KEY
        // - API_KEY
      ]
    }
    template: {
      containers: [
        {
          name: 'backend-api'
          image: '${containerRegistry.properties.loginServer}/${backendImage}'
          resources: {
            cpu: json('0.5')  // TODO: Adjust based on load testing
            memory: '1.0Gi'   // TODO: Adjust based on load testing
          }
          env: [
            // TODO: Add all environment variables from appsettings.json
            // Azure Content Understanding
            // {
            //   name: 'AZURE_CONTENT_UNDERSTANDING_ENDPOINT'
            //   secretRef: 'content-understanding-endpoint'
            // }
            // Azure OpenAI
            // {
            //   name: 'AZURE_OPENAI_ENDPOINT'
            //   secretRef: 'openai-endpoint'
            // }
          ]
          probes: [
            {
              type: 'Readiness'
              httpGet: {
                path: '/health/ready'
                port: 8000
              }
              initialDelaySeconds: 10
              periodSeconds: 10
            }
            {
              type: 'Liveness'
              httpGet: {
                path: '/'
                port: 8000
              }
              initialDelaySeconds: 15
              periodSeconds: 30
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1  // TODO: Adjust for production (e.g., 2+ for HA)
        maxReplicas: 10 // TODO: Adjust based on expected load
      }
    }
  }
}

// =============================================================================
// Frontend Container App
// =============================================================================
resource frontendApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: 'ca-frontend-${environmentName}'
  location: location
  properties: {
    managedEnvironmentId: containerAppEnvironment.id
    configuration: {
      ingress: {
        external: true
        targetPort: 3000
        transport: 'http'
        // TODO: Configure custom domain and SSL
      }
      registries: [
        {
          server: containerRegistry.properties.loginServer
          username: containerRegistry.listCredentials().username
          passwordSecretRef: 'registry-password'
        }
      ]
      secrets: [
        {
          name: 'registry-password'
          value: containerRegistry.listCredentials().passwords[0].value
        }
        // TODO: Add frontend secrets from Key Vault
        // - AUTH_SECRET
        // - API_KEY
      ]
    }
    template: {
      containers: [
        {
          name: 'frontend'
          image: '${containerRegistry.properties.loginServer}/${frontendImage}'
          resources: {
            cpu: json('0.25')  // TODO: Adjust based on load testing
            memory: '0.5Gi'    // TODO: Adjust based on load testing
          }
          env: [
            {
              name: 'API_URL'
              value: 'https://${backendApp.properties.configuration.ingress.fqdn}'
            }
            // TODO: Add all environment variables
            // {
            //   name: 'AUTH_SECRET'
            //   secretRef: 'auth-secret'
            // }
          ]
          probes: [
            {
              type: 'Readiness'
              httpGet: {
                path: '/api/health'
                port: 3000
              }
              initialDelaySeconds: 10
              periodSeconds: 10
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1  // TODO: Adjust for production (e.g., 2+ for HA)
        maxReplicas: 10 // TODO: Adjust based on expected load
      }
    }
  }
}

// =============================================================================
// Outputs
// =============================================================================
output containerRegistryLoginServer string = containerRegistry.properties.loginServer
output containerRegistryName string = containerRegistry.name
output backendUrl string = 'https://${backendApp.properties.configuration.ingress.fqdn}'
output frontendUrl string = 'https://${frontendApp.properties.configuration.ingress.fqdn}'
output containerAppEnvironmentId string = containerAppEnvironment.id
