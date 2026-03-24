# WorkbenchIQ Secrets Setup Guide

This guide explains how to configure secrets for WorkbenchIQ in both local development and Azure production environments.

## 🔐 Security Model

- **Local Development:** .NET User Secrets (stored in user profile, not in source control)
- **Azure Production:** Azure Key Vault with Managed Identity

---

## 📝 Local Development Setup

### Quick Start

Run the interactive setup script:

```powershell
cd WorkbenchIQ\aspire\WorkbenchIQ.AppHost
.\setup-secrets.ps1
```

The script will prompt you for all required secrets and store them securely.

### Manual Setup

If you prefer to set secrets manually:

```powershell
cd WorkbenchIQ\aspire\WorkbenchIQ.AppHost

# Core API Key
dotnet user-secrets set "Parameters:ApiKey" "your-api-key"

# Azure Content Understanding
dotnet user-secrets set "Parameters:ContentUnderstanding:Endpoint" "https://xxx.cognitiveservices.azure.com"
dotnet user-secrets set "Parameters:ContentUnderstanding:ApiKey" "your-key-here"

# Azure OpenAI - Primary
dotnet user-secrets set "Parameters:AzureOpenAI:Endpoint" "https://xxx.openai.azure.com"
dotnet user-secrets set "Parameters:AzureOpenAI:ApiKey" "your-key-here"
dotnet user-secrets set "Parameters:AzureOpenAI:DeploymentName" "gpt-4o"

# Frontend Authentication
dotnet user-secrets set "Parameters:Frontend:AuthSecret" "your-64-char-hex-string"
dotnet user-secrets set "Parameters:Frontend:AuthUser1" "admin:changeme"

# ... (see setup-secrets.ps1 for complete list)
```

### View Your Secrets

```powershell
# List all secrets
dotnet user-secrets list

# Clear all secrets (careful!)
dotnet user-secrets clear
```

### Where Secrets Are Stored

Secrets are stored in your user profile directory:

- **Windows:** `%APPDATA%\Microsoft\UserSecrets\01944af9-bc50-49c9-becf-68636bdb9698\secrets.json`
- **macOS/Linux:** `~/.microsoft/usersecrets/01944af9-bc50-49c9-becf-68636bdb9698/secrets.json`

**Never commit this file to source control!**

---

## ☁️ Azure Production Setup

### Prerequisites

1. Azure subscription with permissions to create:
   - Azure Key Vault
   - Managed Identities
   - Role Assignments

2. Azure CLI installed and logged in:
   ```bash
   az login
   az account set --subscription "your-subscription-id"
   ```

### Deployment Process

When you deploy using Azure Developer CLI or Bicep:

1. **Key Vault is created automatically** by the Bicep template
2. **Managed Identity is assigned** to Container Apps
3. **Role assignments grant access** to Key Vault secrets
4. **Secrets are injected** into Container Apps as environment variables

### Provisioning Secrets in Azure

After deploying the infrastructure, populate Key Vault with secrets:

```bash
# Set resource group and Key Vault name
RG_NAME="rg-workbenchiq-prod"
KV_NAME=$(az keyvault list --resource-group $RG_NAME --query "[0].name" -o tsv)

# Core API Key
az keyvault secret set --vault-name $KV_NAME --name "ApiKey" --value "your-api-key"

# Azure Content Understanding
az keyvault secret set --vault-name $KV_NAME --name "ContentUnderstanding--Endpoint" --value "https://xxx.cognitiveservices.azure.com"
az keyvault secret set --vault-name $KV_NAME --name "ContentUnderstanding--ApiKey" --value "your-key"

# Azure OpenAI - Primary
az keyvault secret set --vault-name $KV_NAME --name "AzureOpenAI--Endpoint" --value "https://xxx.openai.azure.com"
az keyvault secret set --vault-name $KV_NAME --name "AzureOpenAI--ApiKey" --value "your-key"
az keyvault secret set --vault-name $KV_NAME --name "AzureOpenAI--DeploymentName" --value "gpt-4o"

# Azure Storage
az keyvault secret set --vault-name $KV_NAME --name "AzureStorage--AccountName" --value "your-account"
az keyvault secret set --vault-name $KV_NAME --name "AzureStorage--AccountKey" --value "your-key"
az keyvault secret set --vault-name $KV_NAME --name "AzureStorage--ContainerName" --value "workbenchiq"

# Frontend Authentication
az keyvault secret set --vault-name $KV_NAME --name "Frontend--AuthSecret" --value "your-64-char-hex"
az keyvault secret set --vault-name $KV_NAME --name "Frontend--AuthUser1" --value "admin:strongpassword"

# ... (add other secrets as needed)
```

**Note:** Key Vault secret names use `--` instead of `:` for hierarchical configuration keys.

### Verify Key Vault Configuration

```bash
# List all secrets
az keyvault secret list --vault-name $KV_NAME --query "[].name" -o table

# Show secret metadata (not the value)
az keyvault secret show --vault-name $KV_NAME --name "ApiKey"

# Verify managed identity has access
az role assignment list --scope "/subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.KeyVault/vaults/{kv-name}" --query "[?principalType=='ServicePrincipal']"
```

---

## 🔑 Required Secrets Reference

### Core (Required)

| Secret Key | Description | Example |
|------------|-------------|---------|
| `Parameters:ApiKey` | Backend API authentication key | `dev-api-key-123` |

### Azure Content Understanding (Required)

| Secret Key | Description | Example |
|------------|-------------|---------|
| `Parameters:ContentUnderstanding:Endpoint` | Service endpoint | `https://xxx.cognitiveservices.azure.com` |
| `Parameters:ContentUnderstanding:ApiKey` | API key | `abc123...` |

### Azure OpenAI - Primary (Required)

| Secret Key | Description | Example |
|------------|-------------|---------|
| `Parameters:AzureOpenAI:Endpoint` | Service endpoint | `https://xxx.openai.azure.com` |
| `Parameters:AzureOpenAI:ApiKey` | API key | `abc123...` |
| `Parameters:AzureOpenAI:DeploymentName` | Model deployment | `gpt-4o` |

### Azure Storage (Optional)

Only required if `StorageBackend` is set to `azure`:

| Secret Key | Description | Example |
|------------|-------------|---------|
| `Parameters:AzureStorage:AccountName` | Storage account name | `workbenchiqstorage` |
| `Parameters:AzureStorage:AccountKey` | Storage account key | `abc123...` |
| `Parameters:AzureStorage:ContainerName` | Blob container | `documents` |

### Frontend Authentication (Required)

| Secret Key | Description | Example |
|------------|-------------|---------|
| `Parameters:Frontend:AuthSecret` | NextAuth.js secret (64-char hex) | `abcdef0123456789...` |
| `Parameters:Frontend:AuthUser1` | User credentials | `admin:password` |
| `Parameters:Frontend:AuthUser2-5` | Additional users (optional) | `user:password` |

### Azure OpenAI - Chat/Fallback (Optional)

| Secret Key | Description |
|------------|-------------|
| `Parameters:AzureOpenAI:ChatDeploymentName` | Chat-specific deployment |
| `Parameters:AzureOpenAI:ChatModelName` | Chat model name |
| `Parameters:AzureOpenAI:FallbackEndpoint` | Fallback endpoint |
| `Parameters:AzureOpenAI:FallbackApiKey` | Fallback API key |
| `Parameters:AzureOpenAI:FallbackDeploymentName` | Fallback deployment |

---

## 🔍 Troubleshooting

### Local Development

**Problem:** Secrets not being loaded

```powershell
# Verify UserSecretsId is set
dotnet user-secrets list --project .

# Check appsettings configuration
# Ensure Program.cs has User Secrets enabled (automatic in Aspire)
```

**Problem:** Missing required secrets

Run `.\setup-secrets.ps1` to ensure all required secrets are configured.

### Azure Production

**Problem:** Container App can't read Key Vault

```bash
# Verify managed identity exists
az containerapp identity show --name ca-backend-dev --resource-group rg-workbenchiq-dev

# Verify role assignment
az role assignment list --scope /subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.KeyVault/vaults/{kv}
```

**Problem:** Secrets not appearing as environment variables

Check Container App configuration:

```bash
az containerapp show --name ca-backend-dev --resource-group rg-workbenchiq-dev --query "properties.template.containers[0].env" -o table
```

Ensure secrets use `secretRef` pointing to Key Vault:

```bicep
{
  name: 'AZURE_OPENAI_API_KEY'
  secretRef: 'azure-openai-api-key'
}
```

---

## 🛡️ Security Best Practices

1. **Never commit secrets to source control**
   - `.gitignore` excludes `secrets.json` by default
   - `appsettings.json` should have empty values for secrets
   - `appsettings.Development.json` can have non-sensitive dev defaults

2. **Rotate secrets regularly**
   - Update in Key Vault
   - Restart Container Apps to pick up new values

3. **Use different secrets per environment**
   - Dev: User Secrets
   - Staging: Key Vault with staging secrets
   - Production: Key Vault with production secrets

4. **Grant least-privilege access**
   - Container Apps: `Key Vault Secrets User` role only
   - Developers: Use Azure CLI with their own credentials

5. **Monitor secret access**
   - Enable Key Vault diagnostic logs
   - Set up alerts for unauthorized access attempts

---

## 📚 Additional Resources

- [.NET User Secrets documentation](https://learn.microsoft.com/en-us/aspnet/core/security/app-secrets)
- [Azure Key Vault documentation](https://learn.microsoft.com/en-us/azure/key-vault/)
- [Managed Identity documentation](https://learn.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/)
- [.NET Aspire secrets management](https://learn.microsoft.com/en-us/dotnet/aspire/fundamentals/configuration)

---

## ✅ Verification Checklist

### Local Development
- [ ] User Secrets initialized (`dotnet user-secrets list` works)
- [ ] All required secrets configured
- [ ] Application starts without validation errors
- [ ] Services can connect to Azure resources

### Azure Production
- [ ] Key Vault provisioned
- [ ] Managed Identity created and assigned
- [ ] Role assignments configured (`Key Vault Secrets User`)
- [ ] All secrets populated in Key Vault
- [ ] Container Apps reference secrets correctly
- [ ] Application logs show successful secret retrieval
