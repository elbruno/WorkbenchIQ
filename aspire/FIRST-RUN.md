# WorkbenchIQ First-Run Guide

Welcome to WorkbenchIQ! This guide will help you get the application running on your local machine for the first time.

## Prerequisites

Before you begin, ensure you have the following installed:

### Required Software

1. **.NET 10 SDK** (version 10.0.201 or later)
   - Download from: https://dotnet.microsoft.com/download/dotnet/10.0
   - Verify installation: `dotnet --version`

2. **Python 3.10+** (with pip)
   - Download from: https://www.python.org/downloads/
   - Verify installation: `python --version`

3. **Node.js 18+** (with npm)
   - Download from: https://nodejs.org/
   - Verify installation: `node --version`

### Azure Resources

You'll need an active Azure subscription with the following resources provisioned:

1. **Azure OpenAI Service** — Primary endpoint with a deployment (e.g., gpt-4o, gpt-4.1)
2. **Azure Content Understanding** — Cognitive Services endpoint
3. **(Optional)** Azure OpenAI fallback instance for redundancy
4. **(Optional)** Azure Storage Account for cloud-based file storage

## Step 1: Clone and Restore

```bash
# Navigate to the AppHost directory
cd WorkbenchIQ/aspire/WorkbenchIQ.AppHost

# Restore .NET dependencies
dotnet restore
```

## Step 2: First Run

```bash
# Start the Aspire AppHost
dotnet run
```

On first run, the **Aspire Dashboard** will automatically open in your browser (typically at `http://localhost:15000` or `https://localhost:17000`).

## Step 3: Dashboard Prompts

The Aspire Dashboard uses a **parameter prompting mechanism** to collect missing secrets. You'll see a UI prompt for each required parameter.

### What Values to Enter

The dashboard will prompt you for the following secrets (in order):

#### 1. **Core API Authentication**

- **`api-key`** — Backend API authentication key
  - Generate a secure random string (e.g., using `openssl rand -hex 32`)
  - This is used by the frontend to authenticate with the backend

#### 2. **Azure Content Understanding**

- **`content-understanding-endpoint`** — Your Azure Content Understanding endpoint
  - Example: `https://your-resource-name.cognitiveservices.azure.com`
  - Find in: Azure Portal → Your Cognitive Services resource → Keys and Endpoint

- **`content-understanding-api-key`** — API key for Content Understanding
  - Find in: Azure Portal → Your Cognitive Services resource → Keys and Endpoint → Key 1

- **`content-understanding-completion-deployment`** — (Optional) Completion model deployment name
  - Leave blank if not using a custom completion deployment

- **`content-understanding-embedding-deployment`** — (Optional) Embedding model deployment name
  - Leave blank if not using a custom embedding deployment

#### 3. **Azure OpenAI (Primary)**

- **`azure-openai-endpoint`** — Your primary Azure OpenAI endpoint
  - Example: `https://your-resource-name.openai.azure.com`
  - Find in: Azure Portal → Your Azure OpenAI resource → Keys and Endpoint

- **`azure-openai-api-key`** — API key for Azure OpenAI
  - Find in: Azure Portal → Your Azure OpenAI resource → Keys and Endpoint → Key 1

- **`azure-openai-deployment-name`** — The deployment name for your primary model
  - Example: `gpt-4o`, `gpt-4-turbo`, `gpt-4.1`
  - Find in: Azure AI Studio → Deployments

#### 4. **Azure OpenAI (Chat - Optional)**

- **`azure-openai-chat-deployment-name`** — (Optional) Separate deployment for Ask IQ chat
  - Leave blank to use the primary deployment

- **`azure-openai-chat-model-name`** — (Optional) Model name override
  - Leave blank to use defaults

- **`azure-openai-chat-api-version`** — (Optional) API version override
  - Leave blank to use defaults

#### 5. **Azure OpenAI (Fallback - Optional)**

- **`azure-openai-fallback-endpoint`** — (Optional) Fallback Azure OpenAI endpoint
  - Leave blank if you don't have a fallback instance

- **`azure-openai-fallback-api-key`** — (Optional) Fallback API key
  - Leave blank if not using fallback

- **`azure-openai-fallback-deployment-name`** — (Optional) Fallback deployment name
  - Leave blank if not using fallback

- **`azure-openai-fallback-api-version`** — (Optional) Fallback API version
  - Leave blank if not using fallback

#### 6. **Azure Storage (Optional)**

- **`azure-storage-account-name`** — (Optional) Storage account name
  - Only required if `StorageBackend` is set to `"azure"` in `appsettings.json`
  - Find in: Azure Portal → Your Storage Account → Overview

- **`azure-storage-account-key`** — (Optional) Storage account key
  - Find in: Azure Portal → Your Storage Account → Access keys → Key 1

- **`azure-storage-container-name`** — (Optional) Container name
  - Example: `workbenchiq-uploads`

#### 7. **Frontend Authentication**

- **`frontend-auth-secret`** — NextAuth.js secret (required)
  - Generate with: `openssl rand -hex 32`
  - Must be a 64-character hex string

- **`frontend-auth-user-1`** through **`frontend-auth-user-5`** — (Optional) User credentials
  - Format: `username:password`
  - Example: `john.doe:SecureP@ssw0rd`

#### 8. **RAG Configuration (Optional)**

- **`rag-embedding-deployment`** — (Optional) Embedding deployment for RAG
  - Only required if `RAG:Enabled` is set to `"true"` in `appsettings.json`

## Step 4: Persistence

Once you've entered all the required values:

1. The Aspire Dashboard will store them in **.NET User Secrets**
2. Secrets persist across runs — you won't be prompted again unless they're missing
3. Secrets are stored in your user profile, **not in source control**

### Secrets Location

- **Windows:** `%APPDATA%\Microsoft\UserSecrets\01944af9-bc50-49c9-becf-68636bdb9698`
- **macOS/Linux:** `~/.microsoft/usersecrets/01944af9-bc50-49c9-becf-68636bdb9698`

### Managing Secrets

View all secrets:
```bash
dotnet user-secrets list --project .
```

Update a specific secret:
```bash
dotnet user-secrets set "Parameters:api-key" "your-new-value" --project .
```

Remove all secrets:
```bash
dotnet user-secrets clear --project .
```

### Alternative: Interactive Setup Script

If you prefer a guided command-line setup instead of the dashboard prompts:

```powershell
# Run the setup script (PowerShell)
.\setup-secrets.ps1
```

This script will interactively prompt you for each secret and store them in User Secrets.

## Step 5: Verify Services

After secrets are configured, the Aspire Dashboard will show:

1. **backend-api** (Python/FastAPI) — Running on `http://localhost:8000`
2. **frontend** (Next.js) — Running on `http://localhost:3000`

### Health Checks

- Backend: `http://localhost:8000/health/ready`
- Frontend: `http://localhost:3000/api/health`

If health checks are green, you're ready to go!

## Azure Key Vault (Production)

For **production deployments** (Azure Container Apps, App Service), secrets are loaded from **Azure Key Vault** using Managed Identity.

### Setup

1. Create an Azure Key Vault resource
2. Add secrets with naming convention: `AzureOpenAI--Endpoint`, `AzureOpenAI--ApiKey`, etc.
   - Use `--` (double dash) as separator, which maps to `:` in configuration
3. Enable Managed Identity on your container/app
4. Grant the identity "Key Vault Secrets User" role
5. Set environment variable: `AZURE_KEY_VAULT_URI=https://your-vault.vault.azure.net/`

The AppHost will automatically detect the Key Vault URI and load secrets on startup.

## Troubleshooting

### Issue: `.NET 10 SDK not found`

**Solution:** Install .NET 10 SDK from https://dotnet.microsoft.com/download/dotnet/10.0

### Issue: `Python not found` or `python: command not found`

**Solution:**
1. Install Python 3.10+ from https://www.python.org/downloads/
2. Ensure Python is in your PATH
3. On Windows, check "Add Python to PATH" during installation

### Issue: `npm: command not found`

**Solution:** Install Node.js 18+ from https://nodejs.org/

### Issue: Backend fails to start with "Missing Azure credentials"

**Solution:**
1. Verify you entered all required Azure endpoints and API keys in the dashboard
2. Check User Secrets: `dotnet user-secrets list --project .`
3. Ensure endpoints are in the correct format (e.g., `https://xxx.openai.azure.com`)

### Issue: Frontend authentication fails

**Solution:**
1. Ensure `frontend-auth-secret` is a valid 64-character hex string
2. Generate a new one: `openssl rand -hex 32`

### Issue: Services start but health checks fail

**Solution:**
1. Check the Aspire Dashboard logs for detailed error messages
2. Verify Azure credentials are correct
3. Ensure Azure resources are in the same region and subscription

### Issue: Port conflicts (8000 or 3000 already in use)

**Solution:**
1. Stop any other services using those ports
2. Or modify the port numbers in `Program.cs` and update `appsettings.json`

## Next Steps

Once everything is running:

1. **Access the frontend** at `http://localhost:3000`
2. **Log in** using the credentials you configured in `frontend-auth-user-1` (or other user slots)
3. **Explore the Aspire Dashboard** at `http://localhost:15000` or `https://localhost:17000`
   - View distributed traces (OpenTelemetry)
   - Monitor service health
   - View logs and metrics

## Additional Resources

- **Aspire Documentation:** https://learn.microsoft.com/dotnet/aspire/
- **Azure OpenAI Documentation:** https://learn.microsoft.com/azure/ai-services/openai/
- **Azure Content Understanding:** https://learn.microsoft.com/azure/ai-services/content-understanding/

---

**Questions or issues?** Contact Bruno Capuano or check the project documentation.
