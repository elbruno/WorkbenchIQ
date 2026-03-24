# Azure Key Vault Post-Deployment Setup

After deploying the WorkbenchIQ infrastructure to Azure, follow these steps to configure secrets in Key Vault.

## Prerequisites

- Azure CLI installed and logged in
- Contributor access to the resource group
- All Azure service endpoints and API keys available

## Step 1: Get Key Vault Name

After deploying with `azd up` or `az deployment group create`, the Key Vault name will be in the deployment outputs:

```bash
# Get the Key Vault name from deployment outputs
RG_NAME="rg-workbenchiq-dev"  # Replace with your resource group
KV_NAME=$(az keyvault list --resource-group $RG_NAME --query "[0].name" -o tsv)

echo "Key Vault: $KV_NAME"
```

## Step 2: Populate Required Secrets

### Core API Key

```bash
az keyvault secret set --vault-name $KV_NAME \
  --name "ApiKey" \
  --value "your-secure-api-key-here"
```

### Azure Content Understanding

```bash
# Endpoint
az keyvault secret set --vault-name $KV_NAME \
  --name "ContentUnderstanding--Endpoint" \
  --value "https://your-instance.cognitiveservices.azure.com"

# API Key
az keyvault secret set --vault-name $KV_NAME \
  --name "ContentUnderstanding--ApiKey" \
  --value "your-content-understanding-key"

# Optional: Completion Deployment
az keyvault secret set --vault-name $KV_NAME \
  --name "ContentUnderstanding--CompletionDeployment" \
  --value "your-completion-deployment"

# Optional: Embedding Deployment
az keyvault secret set --vault-name $KV_NAME \
  --name "ContentUnderstanding--EmbeddingDeployment" \
  --value "your-embedding-deployment"
```

### Azure OpenAI - Primary

```bash
# Endpoint
az keyvault secret set --vault-name $KV_NAME \
  --name "AzureOpenAI--Endpoint" \
  --value "https://your-openai.openai.azure.com"

# API Key
az keyvault secret set --vault-name $KV_NAME \
  --name "AzureOpenAI--ApiKey" \
  --value "your-openai-key"

# Deployment Name
az keyvault secret set --vault-name $KV_NAME \
  --name "AzureOpenAI--DeploymentName" \
  --value "gpt-4o"
```

### Azure OpenAI - Chat (Optional)

```bash
az keyvault secret set --vault-name $KV_NAME \
  --name "AzureOpenAI--ChatDeploymentName" \
  --value "gpt-4o-chat"

az keyvault secret set --vault-name $KV_NAME \
  --name "AzureOpenAI--ChatModelName" \
  --value "gpt-4o"

az keyvault secret set --vault-name $KV_NAME \
  --name "AzureOpenAI--ChatApiVersion" \
  --value "2024-10-21"
```

### Azure OpenAI - Fallback (Optional)

```bash
az keyvault secret set --vault-name $KV_NAME \
  --name "AzureOpenAI--FallbackEndpoint" \
  --value "https://your-fallback-openai.openai.azure.com"

az keyvault secret set --vault-name $KV_NAME \
  --name "AzureOpenAI--FallbackApiKey" \
  --value "your-fallback-key"

az keyvault secret set --vault-name $KV_NAME \
  --name "AzureOpenAI--FallbackDeploymentName" \
  --value "gpt-4o-fallback"

az keyvault secret set --vault-name $KV_NAME \
  --name "AzureOpenAI--FallbackApiVersion" \
  --value "2024-10-21"
```

### Azure Storage

```bash
az keyvault secret set --vault-name $KV_NAME \
  --name "AzureStorage--AccountName" \
  --value "workbenchiqstorage"

az keyvault secret set --vault-name $KV_NAME \
  --name "AzureStorage--AccountKey" \
  --value "your-storage-account-key"

az keyvault secret set --vault-name $KV_NAME \
  --name "AzureStorage--ContainerName" \
  --value "documents"
```

### Frontend Authentication

```bash
# Generate a secure 64-character hex string for AUTH_SECRET
AUTH_SECRET=$(openssl rand -hex 32)

az keyvault secret set --vault-name $KV_NAME \
  --name "Frontend--AuthSecret" \
  --value "$AUTH_SECRET"

# User credentials (format: username:password)
az keyvault secret set --vault-name $KV_NAME \
  --name "Frontend--AuthUser1" \
  --value "admin:your-secure-password"

# Additional users (optional)
az keyvault secret set --vault-name $KV_NAME \
  --name "Frontend--AuthUser2" \
  --value "user:password"
```

### RAG Configuration (Optional)

```bash
az keyvault secret set --vault-name $KV_NAME \
  --name "RAG--EmbeddingDeployment" \
  --value "text-embedding-3-small"
```

## Step 3: Restart Container Apps

After populating secrets, restart the Container Apps to load the new values:

```bash
# Get Container App names
BACKEND_APP=$(az containerapp list --resource-group $RG_NAME --query "[?contains(name,'backend')].name" -o tsv)
FRONTEND_APP=$(az containerapp list --resource-group $RG_NAME --query "[?contains(name,'frontend')].name" -o tsv)

# Restart backend
az containerapp revision restart \
  --name $BACKEND_APP \
  --resource-group $RG_NAME \
  --revision $(az containerapp revision list --name $BACKEND_APP --resource-group $RG_NAME --query "[0].name" -o tsv)

# Restart frontend
az containerapp revision restart \
  --name $FRONTEND_APP \
  --resource-group $RG_NAME \
  --revision $(az containerapp revision list --name $FRONTEND_APP --resource-group $RG_NAME --query "[0].name" -o tsv)
```

## Step 4: Verify Deployment

### Check Container App URLs

```bash
# Get backend URL
BACKEND_URL=$(az containerapp show --name $BACKEND_APP --resource-group $RG_NAME --query "properties.configuration.ingress.fqdn" -o tsv)
echo "Backend: https://$BACKEND_URL"

# Get frontend URL
FRONTEND_URL=$(az containerapp show --name $FRONTEND_APP --resource-group $RG_NAME --query "properties.configuration.ingress.fqdn" -o tsv)
echo "Frontend: https://$FRONTEND_URL"
```

### Test Backend Health

```bash
curl "https://$BACKEND_URL/health/ready"
# Expected: {"status": "healthy"}
```

### Test Frontend

```bash
curl "https://$FRONTEND_URL/api/health"
# Expected: {"status": "ok"}
```

### Check Container App Logs

```bash
# Backend logs
az containerapp logs show --name $BACKEND_APP --resource-group $RG_NAME --tail 50

# Frontend logs
az containerapp logs show --name $FRONTEND_APP --resource-group $RG_NAME --tail 50
```

## Bulk Secret Update Script

For convenience, create a script to set all secrets at once:

```bash
#!/bin/bash
# populate-secrets.sh

RG_NAME="rg-workbenchiq-dev"
KV_NAME=$(az keyvault list --resource-group $RG_NAME --query "[0].name" -o tsv)

echo "Populating secrets in Key Vault: $KV_NAME"

# Core
az keyvault secret set --vault-name $KV_NAME --name "ApiKey" --value "$API_KEY"

# Content Understanding
az keyvault secret set --vault-name $KV_NAME --name "ContentUnderstanding--Endpoint" --value "$CONTENT_UNDERSTANDING_ENDPOINT"
az keyvault secret set --vault-name $KV_NAME --name "ContentUnderstanding--ApiKey" --value "$CONTENT_UNDERSTANDING_KEY"

# Azure OpenAI
az keyvault secret set --vault-name $KV_NAME --name "AzureOpenAI--Endpoint" --value "$AZURE_OPENAI_ENDPOINT"
az keyvault secret set --vault-name $KV_NAME --name "AzureOpenAI--ApiKey" --value "$AZURE_OPENAI_KEY"
az keyvault secret set --vault-name $KV_NAME --name "AzureOpenAI--DeploymentName" --value "$AZURE_OPENAI_DEPLOYMENT"

# Storage
az keyvault secret set --vault-name $KV_NAME --name "AzureStorage--AccountName" --value "$STORAGE_ACCOUNT_NAME"
az keyvault secret set --vault-name $KV_NAME --name "AzureStorage--AccountKey" --value "$STORAGE_ACCOUNT_KEY"
az keyvault secret set --vault-name $KV_NAME --name "AzureStorage--ContainerName" --value "$STORAGE_CONTAINER"

# Frontend Auth
AUTH_SECRET=$(openssl rand -hex 32)
az keyvault secret set --vault-name $KV_NAME --name "Frontend--AuthSecret" --value "$AUTH_SECRET"
az keyvault secret set --vault-name $KV_NAME --name "Frontend--AuthUser1" --value "$AUTH_USER_1"

echo "✅ Secrets populated successfully"
```

## Troubleshooting

### Secret Not Appearing in Container App

**Issue:** Container App environment variables are empty

**Solution:**
1. Verify managed identity has Key Vault access:
   ```bash
   az role assignment list \
     --scope $(az keyvault show --name $KV_NAME --query id -o tsv) \
     --query "[?principalType=='ServicePrincipal'].{Role:roleDefinitionName,Principal:principalId}"
   ```

2. Ensure secret exists in Key Vault:
   ```bash
   az keyvault secret list --vault-name $KV_NAME --query "[].name" -o table
   ```

3. Check Container App secret references:
   ```bash
   az containerapp show --name $BACKEND_APP --resource-group $RG_NAME \
     --query "properties.configuration.secrets[].name" -o table
   ```

### Access Denied to Key Vault

**Issue:** `(Forbidden) The user, group or application 'appid=xxx' does not have secrets get permission`

**Solution:** Grant the Container App managed identity access to Key Vault:
```bash
BACKEND_PRINCIPAL_ID=$(az containerapp show --name $BACKEND_APP --resource-group $RG_NAME --query "identity.principalId" -o tsv)

az role assignment create \
  --role "Key Vault Secrets User" \
  --assignee $BACKEND_PRINCIPAL_ID \
  --scope $(az keyvault show --name $KV_NAME --query id -o tsv)
```

### Secrets Not Loading in AppHost

**Issue:** Local AppHost can't read Key Vault in production

**Solution:** Ensure `AZURE_KEY_VAULT_URI` environment variable is set in Container App configuration:
```bash
az containerapp show --name $BACKEND_APP --resource-group $RG_NAME \
  --query "properties.template.containers[0].env[?name=='AZURE_KEY_VAULT_URI']"
```

## Security Best Practices

1. **Rotate secrets regularly** (every 90 days recommended)
2. **Use different secrets per environment** (dev, staging, prod)
3. **Never commit secrets to source control**
4. **Enable Key Vault soft delete and purge protection** in production
5. **Monitor Key Vault access logs** for unauthorized attempts
6. **Use least-privilege access** (Container Apps only need "Key Vault Secrets User" role)

## Additional Resources

- [Azure Key Vault documentation](https://learn.microsoft.com/en-us/azure/key-vault/)
- [Container Apps secrets documentation](https://learn.microsoft.com/en-us/azure/container-apps/manage-secrets)
- [Managed Identity documentation](https://learn.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/)
