#!/usr/bin/env pwsh
# =============================================================================
# WorkbenchIQ User Secrets Setup Script
# =============================================================================
# Run this script ONCE to set up your local development secrets.
# Secrets are stored securely in your user profile, not in source control.
#
# Usage: .\setup-secrets.ps1
# =============================================================================

Write-Host "╔═══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║           WorkbenchIQ User Secrets Setup                          ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$projectPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# Check if dotnet is available
if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    Write-Host "❌ ERROR: .NET SDK not found. Please install .NET 10 SDK." -ForegroundColor Red
    exit 1
}

Write-Host "This script will help you configure secrets for local development." -ForegroundColor Yellow
Write-Host "Press Ctrl+C at any time to cancel." -ForegroundColor Yellow
Write-Host ""

# Helper function to set a secret
function Set-UserSecretInteractive {
    param(
        [string]$Key,
        [string]$Description,
        [bool]$Required = $true
    )
    
    $requiredText = if ($Required) { "[REQUIRED]" } else { "[OPTIONAL]" }
    Write-Host "$requiredText $Description" -ForegroundColor $(if ($Required) { "Cyan" } else { "Gray" })
    
    # Check if secret already exists
    $existing = dotnet user-secrets list --project $projectPath 2>&1 | Select-String -Pattern "^$Key = "
    if ($existing) {
        Write-Host "  Current value: [***HIDDEN***]" -ForegroundColor DarkGray
        $update = Read-Host "  Update? (y/n)"
        if ($update -ne 'y' -and $update -ne 'Y') {
            Write-Host "  Skipped." -ForegroundColor DarkGray
            Write-Host ""
            return
        }
    }
    
    if ($Required) {
        do {
            $value = Read-Host "  Enter value"
            if ([string]::IsNullOrWhiteSpace($value)) {
                Write-Host "  ⚠️  This field is required. Please enter a value." -ForegroundColor Yellow
            }
        } while ([string]::IsNullOrWhiteSpace($value))
    } else {
        $value = Read-Host "  Enter value (or press Enter to skip)"
        if ([string]::IsNullOrWhiteSpace($value)) {
            Write-Host "  Skipped." -ForegroundColor DarkGray
            Write-Host ""
            return
        }
    }
    
    dotnet user-secrets set $Key $value --project $projectPath | Out-Null
    Write-Host "  ✅ Set successfully" -ForegroundColor Green
    Write-Host ""
}

# =============================================================================
# Core API Keys
# =============================================================================
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "CORE API KEYS" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Set-UserSecretInteractive `
    -Key "Parameters:api-key" `
    -Description "API Key for backend authentication" `
    -Required $true

# =============================================================================
# Azure Content Understanding
# =============================================================================
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "AZURE CONTENT UNDERSTANDING" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Set-UserSecretInteractive `
    -Key "Parameters:content-understanding-endpoint" `
    -Description "Azure Content Understanding endpoint (e.g., https://xxx.cognitiveservices.azure.com)" `
    -Required $true

Set-UserSecretInteractive `
    -Key "Parameters:content-understanding-api-key" `
    -Description "Azure Content Understanding API key" `
    -Required $true

Set-UserSecretInteractive `
    -Key "Parameters:content-understanding-completion-deployment" `
    -Description "Completion deployment name (optional)" `
    -Required $false

Set-UserSecretInteractive `
    -Key "Parameters:content-understanding-embedding-deployment" `
    -Description "Embedding deployment name (optional)" `
    -Required $false

# =============================================================================
# Azure OpenAI - Primary
# =============================================================================
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "AZURE OPENAI - PRIMARY" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Set-UserSecretInteractive `
    -Key "Parameters:azure-openai-endpoint" `
    -Description "Primary Azure OpenAI endpoint (e.g., https://xxx.openai.azure.com)" `
    -Required $true

Set-UserSecretInteractive `
    -Key "Parameters:azure-openai-api-key" `
    -Description "Primary Azure OpenAI API key" `
    -Required $true

Set-UserSecretInteractive `
    -Key "Parameters:azure-openai-deployment-name" `
    -Description "Primary deployment name (e.g., gpt-4o)" `
    -Required $true

# =============================================================================
# Azure OpenAI - Chat (Ask IQ)
# =============================================================================
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "AZURE OPENAI - CHAT (ASK IQ)" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Set-UserSecretInteractive `
    -Key "Parameters:azure-openai-chat-deployment-name" `
    -Description "Chat deployment name (optional, defaults to primary)" `
    -Required $false

Set-UserSecretInteractive `
    -Key "Parameters:azure-openai-chat-model-name" `
    -Description "Chat model name (optional)" `
    -Required $false

Set-UserSecretInteractive `
    -Key "Parameters:azure-openai-chat-api-version" `
    -Description "Chat API version (optional)" `
    -Required $false

# =============================================================================
# Azure OpenAI - Fallback
# =============================================================================
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "AZURE OPENAI - FALLBACK (OPTIONAL)" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Set-UserSecretInteractive `
    -Key "Parameters:azure-openai-fallback-endpoint" `
    -Description "Fallback Azure OpenAI endpoint (optional)" `
    -Required $false

Set-UserSecretInteractive `
    -Key "Parameters:azure-openai-fallback-api-key" `
    -Description "Fallback Azure OpenAI API key (optional)" `
    -Required $false

Set-UserSecretInteractive `
    -Key "Parameters:azure-openai-fallback-deployment-name" `
    -Description "Fallback deployment name (optional)" `
    -Required $false

Set-UserSecretInteractive `
    -Key "Parameters:azure-openai-fallback-api-version" `
    -Description "Fallback API version (optional)" `
    -Required $false

# =============================================================================
# Azure Storage
# =============================================================================
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "AZURE STORAGE (OPTIONAL)" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Write-Host "Note: Only required if StorageBackend is set to 'azure'" -ForegroundColor Yellow
Write-Host ""

Set-UserSecretInteractive `
    -Key "Parameters:azure-storage-account-name" `
    -Description "Storage account name (optional)" `
    -Required $false

Set-UserSecretInteractive `
    -Key "Parameters:azure-storage-account-key" `
    -Description "Storage account key (optional)" `
    -Required $false

Set-UserSecretInteractive `
    -Key "Parameters:azure-storage-container-name" `
    -Description "Storage container name (optional)" `
    -Required $false

# =============================================================================
# Frontend Authentication
# =============================================================================
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "FRONTEND AUTHENTICATION" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Set-UserSecretInteractive `
    -Key "Parameters:frontend-auth-secret" `
    -Description "NextAuth secret (64-character hex string)" `
    -Required $true

Set-UserSecretInteractive `
    -Key "Parameters:frontend-auth-user-1" `
    -Description "User 1 credentials (format: username:password)" `
    -Required $false

Set-UserSecretInteractive `
    -Key "Parameters:frontend-auth-user-2" `
    -Description "User 2 credentials (format: username:password)" `
    -Required $false

Set-UserSecretInteractive `
    -Key "Parameters:frontend-auth-user-3" `
    -Description "User 3 credentials (format: username:password)" `
    -Required $false

Set-UserSecretInteractive `
    -Key "Parameters:frontend-auth-user-4" `
    -Description "User 4 credentials (format: username:password)" `
    -Required $false

Set-UserSecretInteractive `
    -Key "Parameters:frontend-auth-user-5" `
    -Description "User 5 credentials (format: username:password)" `
    -Required $false

# =============================================================================
# RAG Configuration
# =============================================================================
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "RAG CONFIGURATION (OPTIONAL)" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Write-Host "Note: Only required if RAG:Enabled is set to 'true'" -ForegroundColor Yellow
Write-Host ""

Set-UserSecretInteractive `
    -Key "Parameters:rag-embedding-deployment" `
    -Description "Embedding deployment name (optional)" `
    -Required $false

# =============================================================================
# Summary
# =============================================================================
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "✅ SECRETS SETUP COMPLETE!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "Your secrets are stored securely at:" -ForegroundColor Cyan
Write-Host "  Windows: %APPDATA%\Microsoft\UserSecrets\01944af9-bc50-49c9-becf-68636bdb9698" -ForegroundColor Gray
Write-Host "  macOS/Linux: ~/.microsoft/usersecrets/01944af9-bc50-49c9-becf-68636bdb9698" -ForegroundColor Gray
Write-Host ""
Write-Host "To view your secrets:" -ForegroundColor Cyan
Write-Host "  dotnet user-secrets list --project ." -ForegroundColor Gray
Write-Host ""
Write-Host "To update a specific secret:" -ForegroundColor Cyan
Write-Host "  dotnet user-secrets set 'Parameters:ApiKey' 'your-new-value' --project ." -ForegroundColor Gray
Write-Host ""
Write-Host "Ready to run! Start the application with:" -ForegroundColor Cyan
Write-Host "  dotnet run" -ForegroundColor Gray
Write-Host ""
