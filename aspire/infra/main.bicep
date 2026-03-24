// =============================================================================
// WorkbenchIQ Azure Container Apps Infrastructure
// =============================================================================
// This Bicep template provisions:
// - Azure Key Vault for secure secrets management
// - Azure Container Registry for container images
// - Container Apps Environment with observability
// - Backend API and Frontend Container Apps with managed identities
// - All secrets sourced from Key Vault via managed identity
// =============================================================================

@description('Primary location for all resources')
param location string = resourceGroup().location

@description('Environment name (e.g., dev, staging, prod)')
param environmentName string = 'dev'

@description('Backend container image')
param backendImage string = 'workbenchiq-backend:latest'

@description('Frontend container image')
param frontendImage string = 'workbenchiq-frontend:latest'

@description('Azure tenant ID for Key Vault access')
param tenantId string = tenant().tenantId

// =============================================================================
// Naming Convention
// =============================================================================
var nameSuffix = uniqueString(resourceGroup().id)
var keyVaultName = 'kv-wbiq-${environmentName}-${nameSuffix}'
var containerRegistryName = 'crwbiq${environmentName}${nameSuffix}'
var containerAppEnvName = 'cae-workbenchiq-${environmentName}'
var backendAppName = 'ca-backend-${environmentName}'
var frontendAppName = 'ca-frontend-${environmentName}'
var logAnalyticsName = 'log-workbenchiq-${environmentName}'

// =============================================================================
// Log Analytics Workspace (for Container Apps observability)
// =============================================================================
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// =============================================================================
// Azure Key Vault
// =============================================================================
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenantId
    enableRbacAuthorization: true  // Use RBAC instead of access policies
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    enablePurgeProtection: false  // Allow purge in dev/staging (set to true in production)
    networkAcls: {
      defaultAction: 'Allow'  // TODO: Restrict to VNet in production
      bypass: 'AzureServices'
    }
  }
}

// Placeholder secrets - values MUST be populated after deployment
// Use: az keyvault secret set --vault-name {name} --name {secret-name} --value {value}

// Core API Key
resource secretApiKey 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'ApiKey'
  properties: {
    value: 'PLACEHOLDER-SET-AFTER-DEPLOYMENT'
  }
}

// Azure Content Understanding
resource secretContentUnderstandingEndpoint 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'ContentUnderstanding--Endpoint'
  properties: {
    value: 'PLACEHOLDER-SET-AFTER-DEPLOYMENT'
  }
}

resource secretContentUnderstandingApiKey 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'ContentUnderstanding--ApiKey'
  properties: {
    value: 'PLACEHOLDER-SET-AFTER-DEPLOYMENT'
  }
}

resource secretContentUnderstandingCompletionDeployment 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'ContentUnderstanding--CompletionDeployment'
  properties: {
    value: ''
  }
}

resource secretContentUnderstandingEmbeddingDeployment 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'ContentUnderstanding--EmbeddingDeployment'
  properties: {
    value: ''
  }
}

// Azure OpenAI - Primary
resource secretAzureOpenAIEndpoint 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'AzureOpenAI--Endpoint'
  properties: {
    value: 'PLACEHOLDER-SET-AFTER-DEPLOYMENT'
  }
}

resource secretAzureOpenAIApiKey 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'AzureOpenAI--ApiKey'
  properties: {
    value: 'PLACEHOLDER-SET-AFTER-DEPLOYMENT'
  }
}

resource secretAzureOpenAIDeploymentName 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'AzureOpenAI--DeploymentName'
  properties: {
    value: 'PLACEHOLDER-SET-AFTER-DEPLOYMENT'
  }
}

// Azure OpenAI - Chat (Optional)
resource secretAzureOpenAIChatDeploymentName 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'AzureOpenAI--ChatDeploymentName'
  properties: {
    value: ''
  }
}

resource secretAzureOpenAIChatModelName 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'AzureOpenAI--ChatModelName'
  properties: {
    value: ''
  }
}

resource secretAzureOpenAIChatApiVersion 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'AzureOpenAI--ChatApiVersion'
  properties: {
    value: ''
  }
}

// Azure OpenAI - Fallback (Optional)
resource secretAzureOpenAIFallbackEndpoint 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'AzureOpenAI--FallbackEndpoint'
  properties: {
    value: ''
  }
}

resource secretAzureOpenAIFallbackApiKey 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'AzureOpenAI--FallbackApiKey'
  properties: {
    value: ''
  }
}

resource secretAzureOpenAIFallbackDeploymentName 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'AzureOpenAI--FallbackDeploymentName'
  properties: {
    value: ''
  }
}

resource secretAzureOpenAIFallbackApiVersion 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'AzureOpenAI--FallbackApiVersion'
  properties: {
    value: ''
  }
}

// Azure Storage
resource secretAzureStorageAccountName 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'AzureStorage--AccountName'
  properties: {
    value: ''
  }
}

resource secretAzureStorageAccountKey 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'AzureStorage--AccountKey'
  properties: {
    value: ''
  }
}

resource secretAzureStorageContainerName 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'AzureStorage--ContainerName'
  properties: {
    value: ''
  }
}

// Frontend Authentication
resource secretFrontendAuthSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'Frontend--AuthSecret'
  properties: {
    value: 'PLACEHOLDER-SET-AFTER-DEPLOYMENT'
  }
}

resource secretFrontendAuthUser1 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'Frontend--AuthUser1'
  properties: {
    value: ''
  }
}

resource secretFrontendAuthUser2 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'Frontend--AuthUser2'
  properties: {
    value: ''
  }
}

resource secretFrontendAuthUser3 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'Frontend--AuthUser3'
  properties: {
    value: ''
  }
}

resource secretFrontendAuthUser4 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'Frontend--AuthUser4'
  properties: {
    value: ''
  }
}

resource secretFrontendAuthUser5 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'Frontend--AuthUser5'
  properties: {
    value: ''
  }
}

// RAG Configuration
resource secretRAGEmbeddingDeployment 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'RAG--EmbeddingDeployment'
  properties: {
    value: ''
  }
}

// =============================================================================
// Container Registry
// =============================================================================
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: containerRegistryName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true  // Needed for CI/CD image push (dev/staging only)
  }
}

// =============================================================================
// Container Apps Environment
// =============================================================================
resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: containerAppEnvName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
    zoneRedundant: false  // TODO: Enable for production HA
  }
}

// =============================================================================
// Backend API Container App
// =============================================================================
resource backendApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: backendAppName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: containerAppEnvironment.id
    configuration: {
      ingress: {
        external: true
        targetPort: 8000
        transport: 'http'
        allowInsecure: false
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
        // Secrets sourced from Key Vault
        {
          name: 'api-key'
          keyVaultUrl: '${keyVault.properties.vaultUri}secrets/${secretApiKey.name}'
          identity: 'system'
        }
        {
          name: 'content-understanding-endpoint'
          keyVaultUrl: '${keyVault.properties.vaultUri}secrets/${secretContentUnderstandingEndpoint.name}'
          identity: 'system'
        }
        {
          name: 'content-understanding-api-key'
          keyVaultUrl: '${keyVault.properties.vaultUri}secrets/${secretContentUnderstandingApiKey.name}'
          identity: 'system'
        }
        {
          name: 'content-understanding-completion-deployment'
          keyVaultUrl: '${keyVault.properties.vaultUri}secrets/${secretContentUnderstandingCompletionDeployment.name}'
          identity: 'system'
        }
        {
          name: 'content-understanding-embedding-deployment'
          keyVaultUrl: '${keyVault.properties.vaultUri}secrets/${secretContentUnderstandingEmbeddingDeployment.name}'
          identity: 'system'
        }
        {
          name: 'azure-openai-endpoint'
          keyVaultUrl: '${keyVault.properties.vaultUri}secrets/${secretAzureOpenAIEndpoint.name}'
          identity: 'system'
        }
        {
          name: 'azure-openai-api-key'
          keyVaultUrl: '${keyVault.properties.vaultUri}secrets/${secretAzureOpenAIApiKey.name}'
          identity: 'system'
        }
        {
          name: 'azure-openai-deployment-name'
          keyVaultUrl: '${keyVault.properties.vaultUri}secrets/${secretAzureOpenAIDeploymentName.name}'
          identity: 'system'
        }
        {
          name: 'azure-openai-chat-deployment-name'
          keyVaultUrl: '${keyVault.properties.vaultUri}secrets/${secretAzureOpenAIChatDeploymentName.name}'
          identity: 'system'
        }
        {
          name: 'azure-openai-chat-model-name'
          keyVaultUrl: '${keyVault.properties.vaultUri}secrets/${secretAzureOpenAIChatModelName.name}'
          identity: 'system'
        }
        {
          name: 'azure-openai-chat-api-version'
          keyVaultUrl: '${keyVault.properties.vaultUri}secrets/${secretAzureOpenAIChatApiVersion.name}'
          identity: 'system'
        }
        {
          name: 'azure-openai-fallback-endpoint'
          keyVaultUrl: '${keyVault.properties.vaultUri}secrets/${secretAzureOpenAIFallbackEndpoint.name}'
          identity: 'system'
        }
        {
          name: 'azure-openai-fallback-api-key'
          keyVaultUrl: '${keyVault.properties.vaultUri}secrets/${secretAzureOpenAIFallbackApiKey.name}'
          identity: 'system'
        }
        {
          name: 'azure-openai-fallback-deployment-name'
          keyVaultUrl: '${keyVault.properties.vaultUri}secrets/${secretAzureOpenAIFallbackDeploymentName.name}'
          identity: 'system'
        }
        {
          name: 'azure-openai-fallback-api-version'
          keyVaultUrl: '${keyVault.properties.vaultUri}secrets/${secretAzureOpenAIFallbackApiVersion.name}'
          identity: 'system'
        }
        {
          name: 'azure-storage-account-name'
          keyVaultUrl: '${keyVault.properties.vaultUri}secrets/${secretAzureStorageAccountName.name}'
          identity: 'system'
        }
        {
          name: 'azure-storage-account-key'
          keyVaultUrl: '${keyVault.properties.vaultUri}secrets/${secretAzureStorageAccountKey.name}'
          identity: 'system'
        }
        {
          name: 'azure-storage-container-name'
          keyVaultUrl: '${keyVault.properties.vaultUri}secrets/${secretAzureStorageContainerName.name}'
          identity: 'system'
        }
        {
          name: 'rag-embedding-deployment'
          keyVaultUrl: '${keyVault.properties.vaultUri}secrets/${secretRAGEmbeddingDeployment.name}'
          identity: 'system'
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'backend-api'
          image: '${containerRegistry.properties.loginServer}/${backendImage}'
          resources: {
            cpu: json('0.5')
            memory: '1.0Gi'
          }
          env: [
            // API Key
            {
              name: 'API_KEY'
              secretRef: 'api-key'
            }
            // Azure Content Understanding
            {
              name: 'AZURE_CONTENT_UNDERSTANDING_ENDPOINT'
              secretRef: 'content-understanding-endpoint'
            }
            {
              name: 'AZURE_CONTENT_UNDERSTANDING_API_KEY'
              secretRef: 'content-understanding-api-key'
            }
            {
              name: 'AZURE_CONTENT_UNDERSTANDING_ANALYZER_ID'
              value: 'prebuilt-documentSearch'
            }
            {
              name: 'AZURE_CONTENT_UNDERSTANDING_API_VERSION'
              value: '2025-11-01'
            }
            {
              name: 'AZURE_CONTENT_UNDERSTANDING_USE_AZURE_AD'
              value: 'true'
            }
            {
              name: 'AZURE_CONTENT_UNDERSTANDING_COMPLETION_DEPLOYMENT'
              secretRef: 'content-understanding-completion-deployment'
            }
            {
              name: 'AZURE_CONTENT_UNDERSTANDING_EMBEDDING_DEPLOYMENT'
              secretRef: 'content-understanding-embedding-deployment'
            }
            // Azure OpenAI - Primary
            {
              name: 'AZURE_OPENAI_ENDPOINT'
              secretRef: 'azure-openai-endpoint'
            }
            {
              name: 'AZURE_OPENAI_API_KEY'
              secretRef: 'azure-openai-api-key'
            }
            {
              name: 'AZURE_OPENAI_DEPLOYMENT_NAME'
              secretRef: 'azure-openai-deployment-name'
            }
            {
              name: 'AZURE_OPENAI_API_VERSION'
              value: '2024-10-21'
            }
            {
              name: 'AZURE_OPENAI_MODEL_NAME'
              value: 'gpt-4.1'
            }
            {
              name: 'AZURE_OPENAI_USE_AZURE_AD'
              value: 'true'
            }
            // Azure OpenAI - Chat
            {
              name: 'AZURE_OPENAI_CHAT_DEPLOYMENT_NAME'
              secretRef: 'azure-openai-chat-deployment-name'
            }
            {
              name: 'AZURE_OPENAI_CHAT_MODEL_NAME'
              secretRef: 'azure-openai-chat-model-name'
            }
            {
              name: 'AZURE_OPENAI_CHAT_API_VERSION'
              secretRef: 'azure-openai-chat-api-version'
            }
            // Azure OpenAI - Fallback
            {
              name: 'AZURE_OPENAI_FALLBACK_ENDPOINT'
              secretRef: 'azure-openai-fallback-endpoint'
            }
            {
              name: 'AZURE_OPENAI_FALLBACK_API_KEY'
              secretRef: 'azure-openai-fallback-api-key'
            }
            {
              name: 'AZURE_OPENAI_FALLBACK_DEPLOYMENT_NAME'
              secretRef: 'azure-openai-fallback-deployment-name'
            }
            {
              name: 'AZURE_OPENAI_FALLBACK_API_VERSION'
              secretRef: 'azure-openai-fallback-api-version'
            }
            {
              name: 'AZURE_OPENAI_FALLBACK_USE_AZURE_AD'
              value: 'false'
            }
            // Azure Storage
            {
              name: 'STORAGE_BACKEND'
              value: 'azure'
            }
            {
              name: 'AZURE_STORAGE_ACCOUNT_NAME'
              secretRef: 'azure-storage-account-name'
            }
            {
              name: 'AZURE_STORAGE_ACCOUNT_KEY'
              secretRef: 'azure-storage-account-key'
            }
            {
              name: 'AZURE_STORAGE_CONTAINER_NAME'
              secretRef: 'azure-storage-container-name'
            }
            {
              name: 'AZURE_STORAGE_TIMEOUT_SECONDS'
              value: '30'
            }
            {
              name: 'AZURE_STORAGE_RETRY_TOTAL'
              value: '3'
            }
            // Application Settings
            {
              name: 'UW_APP_STORAGE_ROOT'
              value: 'data'
            }
            {
              name: 'UW_APP_PROMPTS_ROOT'
              value: 'prompts'
            }
            {
              name: 'PUBLIC_FILES_BASE_URL'
              value: ''
            }
            {
              name: 'DATABASE_BACKEND'
              value: 'json'
            }
            // RAG Settings
            {
              name: 'RAG_ENABLED'
              value: 'false'
            }
            {
              name: 'RAG_TOP_K'
              value: '5'
            }
            {
              name: 'RAG_SIMILARITY_THRESHOLD'
              value: '0.5'
            }
            {
              name: 'EMBEDDING_MODEL'
              value: 'text-embedding-3-small'
            }
            {
              name: 'EMBEDDING_DIMENSIONS'
              value: '1536'
            }
            {
              name: 'EMBEDDING_DEPLOYMENT'
              secretRef: 'rag-embedding-deployment'
            }
            // Processing Settings
            {
              name: 'LARGE_DOC_THRESHOLD_KB'
              value: '1500'
            }
            {
              name: 'CHUNK_SIZE_CHARS'
              value: '50000'
            }
            {
              name: 'MAX_SAMPLE_PAGES'
              value: '15'
            }
            {
              name: 'CONDENSED_CONTEXT_MAX_CHARS'
              value: '40000'
            }
            {
              name: 'AUTO_DETECT_PROCESSING_MODE'
              value: 'true'
            }
            // Automotive Claims Settings
            {
              name: 'AUTO_CLAIMS_ENABLED'
              value: 'true'
            }
            {
              name: 'AUTO_CLAIMS_DOC_ANALYZER'
              value: 'autoClaimsDocAnalyzer'
            }
            {
              name: 'AUTO_CLAIMS_IMAGE_ANALYZER'
              value: 'autoClaimsImageAnalyzer'
            }
            {
              name: 'AUTO_CLAIMS_VIDEO_ANALYZER'
              value: 'autoClaimsVideoAnalyzer'
            }
            {
              name: 'AUTO_CLAIMS_POLICIES_PATH'
              value: 'prompts/automotive-claims-policies.json'
            }
            {
              name: 'VIDEO_MAX_DURATION_MINUTES'
              value: '10'
            }
            {
              name: 'IMAGE_MAX_SIZE_MB'
              value: '20'
            }
            // Mortgage Underwriting Settings
            {
              name: 'MORTGAGE_ENABLED'
              value: 'true'
            }
            {
              name: 'MORTGAGE_DOC_ANALYZER'
              value: 'mortgageDocAnalyzer'
            }
            {
              name: 'MORTGAGE_POLICIES_PATH'
              value: 'prompts/mortgage-underwriting-policies.json'
            }
            {
              name: 'OSFI_MQR_FLOOR_PCT'
              value: '5.25'
            }
            {
              name: 'OSFI_MQR_BUFFER_PCT'
              value: '2.0'
            }
            {
              name: 'GDS_LIMIT_STANDARD'
              value: '0.39'
            }
            {
              name: 'TDS_LIMIT_STANDARD'
              value: '0.44'
            }
            {
              name: 'LTV_LIMIT_CONVENTIONAL'
              value: '0.80'
            }
            {
              name: 'LTV_LIMIT_INSURED'
              value: '0.95'
            }
            {
              name: 'MAX_AMORT_INSURED'
              value: '25'
            }
            {
              name: 'MAX_AMORT_UNINSURED'
              value: '30'
            }
            // Key Vault URI for AppHost
            {
              name: 'AZURE_KEY_VAULT_URI'
              value: keyVault.properties.vaultUri
            }
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
        minReplicas: 1
        maxReplicas: 10
        rules: [
          {
            name: 'http-scaling'
            http: {
              metadata: {
                concurrentRequests: '50'
              }
            }
          }
        ]
      }
    }
  }
}

// =============================================================================
// Frontend Container App
// =============================================================================
resource frontendApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: frontendAppName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: containerAppEnvironment.id
    configuration: {
      ingress: {
        external: true
        targetPort: 3000
        transport: 'http'
        allowInsecure: false
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
        // Secrets sourced from Key Vault
        {
          name: 'api-key'
          keyVaultUrl: '${keyVault.properties.vaultUri}secrets/${secretApiKey.name}'
          identity: 'system'
        }
        {
          name: 'frontend-auth-secret'
          keyVaultUrl: '${keyVault.properties.vaultUri}secrets/${secretFrontendAuthSecret.name}'
          identity: 'system'
        }
        {
          name: 'frontend-auth-user1'
          keyVaultUrl: '${keyVault.properties.vaultUri}secrets/${secretFrontendAuthUser1.name}'
          identity: 'system'
        }
        {
          name: 'frontend-auth-user2'
          keyVaultUrl: '${keyVault.properties.vaultUri}secrets/${secretFrontendAuthUser2.name}'
          identity: 'system'
        }
        {
          name: 'frontend-auth-user3'
          keyVaultUrl: '${keyVault.properties.vaultUri}secrets/${secretFrontendAuthUser3.name}'
          identity: 'system'
        }
        {
          name: 'frontend-auth-user4'
          keyVaultUrl: '${keyVault.properties.vaultUri}secrets/${secretFrontendAuthUser4.name}'
          identity: 'system'
        }
        {
          name: 'frontend-auth-user5'
          keyVaultUrl: '${keyVault.properties.vaultUri}secrets/${secretFrontendAuthUser5.name}'
          identity: 'system'
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'frontend'
          image: '${containerRegistry.properties.loginServer}/${frontendImage}'
          resources: {
            cpu: json('0.25')
            memory: '0.5Gi'
          }
          env: [
            {
              name: 'API_URL'
              value: 'https://${backendApp.properties.configuration.ingress.fqdn}'
            }
            {
              name: 'API_KEY'
              secretRef: 'api-key'
            }
            {
              name: 'AUTH_SECRET'
              secretRef: 'frontend-auth-secret'
            }
            {
              name: 'AUTH_USER_1'
              secretRef: 'frontend-auth-user1'
            }
            {
              name: 'AUTH_USER_2'
              secretRef: 'frontend-auth-user2'
            }
            {
              name: 'AUTH_USER_3'
              secretRef: 'frontend-auth-user3'
            }
            {
              name: 'AUTH_USER_4'
              secretRef: 'frontend-auth-user4'
            }
            {
              name: 'AUTH_USER_5'
              secretRef: 'frontend-auth-user5'
            }
            // Key Vault URI for AppHost
            {
              name: 'AZURE_KEY_VAULT_URI'
              value: keyVault.properties.vaultUri
            }
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
        minReplicas: 1
        maxReplicas: 10
        rules: [
          {
            name: 'http-scaling'
            http: {
              metadata: {
                concurrentRequests: '100'
              }
            }
          }
        ]
      }
    }
  }
}

// =============================================================================
// Role Assignments - Grant Container Apps access to Key Vault
// =============================================================================
// Backend API - Key Vault Secrets User role
resource backendKeyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, backendApp.id, 'Key Vault Secrets User')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6') // Key Vault Secrets User
    principalId: backendApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Frontend - Key Vault Secrets User role
resource frontendKeyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, frontendApp.id, 'Key Vault Secrets User')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6') // Key Vault Secrets User
    principalId: frontendApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// =============================================================================
// Outputs
// =============================================================================
output keyVaultName string = keyVault.name
output keyVaultUri string = keyVault.properties.vaultUri
output containerRegistryLoginServer string = containerRegistry.properties.loginServer
output containerRegistryName string = containerRegistry.name
output backendUrl string = 'https://${backendApp.properties.configuration.ingress.fqdn}'
output frontendUrl string = 'https://${frontendApp.properties.configuration.ingress.fqdn}'
output containerAppEnvironmentId string = containerAppEnvironment.id
output backendIdentityPrincipalId string = backendApp.identity.principalId
output frontendIdentityPrincipalId string = frontendApp.identity.principalId
output logAnalyticsWorkspaceId string = logAnalytics.id

// Post-deployment instructions
output postDeploymentInstructions string = '''
=============================================================================
NEXT STEPS: Configure Secrets in Key Vault
=============================================================================

1. Set required secrets using Azure CLI:

   az keyvault secret set --vault-name ${keyVaultName} --name "ApiKey" --value "your-api-key"
   az keyvault secret set --vault-name ${keyVaultName} --name "ContentUnderstanding--Endpoint" --value "https://xxx.cognitiveservices.azure.com"
   az keyvault secret set --vault-name ${keyVaultName} --name "ContentUnderstanding--ApiKey" --value "your-key"
   az keyvault secret set --vault-name ${keyVaultName} --name "AzureOpenAI--Endpoint" --value "https://xxx.openai.azure.com"
   az keyvault secret set --vault-name ${keyVaultName} --name "AzureOpenAI--ApiKey" --value "your-key"
   az keyvault secret set --vault-name ${keyVaultName} --name "AzureOpenAI--DeploymentName" --value "gpt-4o"
   az keyvault secret set --vault-name ${keyVaultName} --name "Frontend--AuthSecret" --value "your-64-char-hex"

2. Restart Container Apps to load secrets:

   az containerapp revision restart --name ${backendAppName} --resource-group ${resourceGroup().name}
   az containerapp revision restart --name ${frontendAppName} --resource-group ${resourceGroup().name}

3. Verify deployment:

   Backend:  ${backendApp.properties.configuration.ingress.fqdn}
   Frontend: ${frontendApp.properties.configuration.ingress.fqdn}

For complete secrets reference, see: WorkbenchIQ/aspire/WorkbenchIQ.AppHost/SECRETS-SETUP.md
=============================================================================
'''
