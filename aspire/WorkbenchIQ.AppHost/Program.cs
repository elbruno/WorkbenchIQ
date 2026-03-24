using Azure.Identity;
using Azure.Security.KeyVault.Secrets;
using Azure.Extensions.AspNetCore.Configuration.Secrets;
using Microsoft.Extensions.Configuration;

var builder = DistributedApplication.CreateBuilder(args);

// =============================================================================
// Azure Key Vault Configuration (Production)
// =============================================================================
// When deployed to Azure, load secrets from Key Vault using Managed Identity.
// Key Vault URI should be provided via AZURE_KEY_VAULT_URI environment variable.
var keyVaultUri = Environment.GetEnvironmentVariable("AZURE_KEY_VAULT_URI");
if (!string.IsNullOrEmpty(keyVaultUri))
{
    var secretClient = new SecretClient(new Uri(keyVaultUri), new DefaultAzureCredential());
    
    // Create a ConfigurationBuilder to add Key Vault secrets
    var configBuilder = new ConfigurationBuilder();
    foreach (var source in builder.Configuration.Sources)
    {
        configBuilder.Sources.Add(source);
    }
    
    // Add Key Vault secrets with custom prefix mapper
    // Key Vault secrets use '--' (e.g., 'AzureOpenAI--Endpoint')
    // which maps to 'Parameters:AzureOpenAI:Endpoint' in configuration
    configBuilder.AddAzureKeyVault(secretClient, new PrefixKeyVaultSecretManager("Parameters"));
    
    // Build and replace the configuration
    var config = configBuilder.Build();
    foreach (var kvp in config.AsEnumerable())
    {
        if (kvp.Value != null)
        {
            builder.Configuration[kvp.Key] = kvp.Value;
        }
    }
    
    Console.WriteLine($"✅ Azure Key Vault configured: {keyVaultUri}");
}
else
{
    var environment = builder.Environment.EnvironmentName;
    if (environment == "Development")
    {
        Console.WriteLine("ℹ️  Running in development mode. Using User Secrets for configuration.");
        Console.WriteLine("   Run './setup-secrets.ps1' to configure your local secrets.");
    }
    else
    {
        Console.WriteLine("⚠️  AZURE_KEY_VAULT_URI not set. Secrets will be loaded from configuration only.");
    }
}
// Note: User Secrets are automatically loaded in development by default

// =============================================================================
// Deployment Mode Detection
// =============================================================================
// When ASPIRE_DEPLOY is set, use container-based orchestration for deployment.
// Otherwise, use process-based orchestration for local development.
var isDeployMode = !string.IsNullOrEmpty(Environment.GetEnvironmentVariable("ASPIRE_DEPLOY"));

if (isDeployMode)
{
    // =============================================================================
    // DEPLOYMENT MODE: Container-based orchestration for Azure Container Apps
    // =============================================================================
    // Environment variables are injected by Azure Container Apps configuration.
    // The Bicep template (aspire/infra/main.bicep) handles secrets and environment.
    
    builder.AddContainer("backend-api", "workbenchiq-backend", "latest")
        .WithHttpEndpoint(port: 8000, name: "http")
        .WithExternalHttpEndpoints()
        .WithHttpHealthCheck("/health/ready");
    
    builder.AddContainer("frontend", "workbenchiq-frontend", "latest")
        .WithHttpEndpoint(port: 3000, name: "http", isProxied: false)
        .WithExternalHttpEndpoints()
        .WithHttpHealthCheck("/api/health");
}
else
{
    // =============================================================================
    // LOCAL DEVELOPMENT MODE: Process-based orchestration
    // =============================================================================
    
    // =============================================================================
    // Parameters — Aspire Dashboard will prompt for missing values on first run
    // =============================================================================
    
    // --- Core API Authentication ---
    var apiKey = builder.AddParameter("api-key", secret: true);
    
    // --- Azure Content Understanding ---
    var cuEndpoint = builder.AddParameter("content-understanding-endpoint");
    var cuApiKey = builder.AddParameter("content-understanding-api-key", secret: true);
    var cuCompletionDeployment = builder.AddParameter("content-understanding-completion-deployment");
    var cuEmbeddingDeployment = builder.AddParameter("content-understanding-embedding-deployment");
    
    // --- Azure OpenAI (Primary) ---
    var openAiEndpoint = builder.AddParameter("azure-openai-endpoint");
    var openAiApiKey = builder.AddParameter("azure-openai-api-key", secret: true);
    var openAiDeploymentName = builder.AddParameter("azure-openai-deployment-name");
    
    // --- Azure OpenAI (Chat-specific for Ask IQ) ---
    var openAiChatDeploymentName = builder.AddParameter("azure-openai-chat-deployment-name");
    var openAiChatModelName = builder.AddParameter("azure-openai-chat-model-name");
    var openAiChatApiVersion = builder.AddParameter("azure-openai-chat-api-version");
    
    // --- Azure OpenAI (Fallback) ---
    var openAiFallbackEndpoint = builder.AddParameter("azure-openai-fallback-endpoint");
    var openAiFallbackApiKey = builder.AddParameter("azure-openai-fallback-api-key", secret: true);
    var openAiFallbackDeploymentName = builder.AddParameter("azure-openai-fallback-deployment-name");
    var openAiFallbackApiVersion = builder.AddParameter("azure-openai-fallback-api-version");
    
    // --- Azure Storage (optional) ---
    var storageAccountName = builder.AddParameter("azure-storage-account-name");
    var storageAccountKey = builder.AddParameter("azure-storage-account-key", secret: true);
    var storageContainerName = builder.AddParameter("azure-storage-container-name");
    
    // --- Frontend Authentication ---
    var frontendAuthSecret = builder.AddParameter("frontend-auth-secret", secret: true);
    var frontendAuthUser1 = builder.AddParameter("frontend-auth-user-1", secret: true);
    var frontendAuthUser2 = builder.AddParameter("frontend-auth-user-2", secret: true);
    var frontendAuthUser3 = builder.AddParameter("frontend-auth-user-3", secret: true);
    var frontendAuthUser4 = builder.AddParameter("frontend-auth-user-4", secret: true);
    var frontendAuthUser5 = builder.AddParameter("frontend-auth-user-5", secret: true);
    
    // --- RAG Embedding Deployment (optional) ---
    var ragEmbeddingDeployment = builder.AddParameter("rag-embedding-deployment");
    
    // Optional PostgreSQL Container (for local development)
    var enablePostgres = builder.Configuration["Parameters:EnablePostgres"]?.Equals("true", StringComparison.OrdinalIgnoreCase) ?? false;
    
    IResourceBuilder<PostgresServerResource>? postgres = null;
    IResourceBuilder<PostgresDatabaseResource>? workbenchiqDb = null;
    
    if (enablePostgres)
    {
        postgres = builder.AddPostgres("postgres")
            .WithPgAdmin();
        workbenchiqDb = postgres.AddDatabase("workbenchiq");
    }
    
    // Backend API (Python/FastAPI)
    var backend = builder.AddPythonApp("backend-api", "../../", "api_server.py")
        .WithHttpEndpoint(port: 8000, name: "http")
        .WithExternalHttpEndpoints()
        .WithHttpHealthCheck("/health/ready")
    // Azure Content Understanding
    .WithEnvironment("AZURE_CONTENT_UNDERSTANDING_ENDPOINT", cuEndpoint)
    .WithEnvironment("AZURE_CONTENT_UNDERSTANDING_API_KEY", cuApiKey)
    .WithEnvironment("AZURE_CONTENT_UNDERSTANDING_ANALYZER_ID",
        builder.Configuration["Parameters:ContentUnderstanding:AnalyzerId"] ?? "prebuilt-documentSearch")
    .WithEnvironment("AZURE_CONTENT_UNDERSTANDING_API_VERSION",
        builder.Configuration["Parameters:ContentUnderstanding:ApiVersion"] ?? "2025-11-01")
    .WithEnvironment("AZURE_CONTENT_UNDERSTANDING_USE_AZURE_AD",
        builder.Configuration["Parameters:ContentUnderstanding:UseAzureAD"] ?? "true")
    .WithEnvironment("AZURE_CONTENT_UNDERSTANDING_COMPLETION_DEPLOYMENT", cuCompletionDeployment)
    .WithEnvironment("AZURE_CONTENT_UNDERSTANDING_EMBEDDING_DEPLOYMENT", cuEmbeddingDeployment)
    // Azure OpenAI (Primary)
    .WithEnvironment("AZURE_OPENAI_ENDPOINT", openAiEndpoint)
    .WithEnvironment("AZURE_OPENAI_API_KEY", openAiApiKey)
    .WithEnvironment("AZURE_OPENAI_DEPLOYMENT_NAME", openAiDeploymentName)
    .WithEnvironment("AZURE_OPENAI_API_VERSION",
        builder.Configuration["Parameters:AzureOpenAI:ApiVersion"] ?? "2024-10-21")
    .WithEnvironment("AZURE_OPENAI_MODEL_NAME",
        builder.Configuration["Parameters:AzureOpenAI:ModelName"] ?? "gpt-4.1")
    .WithEnvironment("AZURE_OPENAI_USE_AZURE_AD",
        builder.Configuration["Parameters:AzureOpenAI:UseAzureAD"] ?? "true")
    // Azure OpenAI (Chat-specific for Ask IQ)
    .WithEnvironment("AZURE_OPENAI_CHAT_DEPLOYMENT_NAME", openAiChatDeploymentName)
    .WithEnvironment("AZURE_OPENAI_CHAT_MODEL_NAME", openAiChatModelName)
    .WithEnvironment("AZURE_OPENAI_CHAT_API_VERSION", openAiChatApiVersion)
    // Azure OpenAI (Fallback)
    .WithEnvironment("AZURE_OPENAI_FALLBACK_ENDPOINT", openAiFallbackEndpoint)
    .WithEnvironment("AZURE_OPENAI_FALLBACK_API_KEY", openAiFallbackApiKey)
    .WithEnvironment("AZURE_OPENAI_FALLBACK_DEPLOYMENT_NAME", openAiFallbackDeploymentName)
    .WithEnvironment("AZURE_OPENAI_FALLBACK_API_VERSION", openAiFallbackApiVersion)
    .WithEnvironment("AZURE_OPENAI_FALLBACK_USE_AZURE_AD",
        builder.Configuration["Parameters:AzureOpenAI:FallbackUseAzureAD"] ?? "false")
    // Azure Storage
    .WithEnvironment("STORAGE_BACKEND",
        builder.Configuration["Parameters:StorageBackend"] ?? "local")
    .WithEnvironment("AZURE_STORAGE_ACCOUNT_NAME", storageAccountName)
    .WithEnvironment("AZURE_STORAGE_ACCOUNT_KEY", storageAccountKey)
    .WithEnvironment("AZURE_STORAGE_CONTAINER_NAME", storageContainerName)
    .WithEnvironment("AZURE_STORAGE_TIMEOUT_SECONDS",
        builder.Configuration["Parameters:AzureStorage:TimeoutSeconds"] ?? "30")
    .WithEnvironment("AZURE_STORAGE_RETRY_TOTAL",
        builder.Configuration["Parameters:AzureStorage:RetryTotal"] ?? "3")
    // Application Settings
    .WithEnvironment("UW_APP_STORAGE_ROOT",
        builder.Configuration["Parameters:App:StorageRoot"] ?? "data")
    .WithEnvironment("UW_APP_PROMPTS_ROOT",
        builder.Configuration["Parameters:App:PromptsRoot"] ?? "prompts")
    .WithEnvironment("PUBLIC_FILES_BASE_URL",
        builder.Configuration["Parameters:App:PublicFilesBaseUrl"] ?? "")
    .WithEnvironment("API_KEY", apiKey)
    // RAG Settings
    .WithEnvironment("RAG_ENABLED",
        builder.Configuration["Parameters:RAG:Enabled"] ?? "false")
    .WithEnvironment("RAG_TOP_K",
        builder.Configuration["Parameters:RAG:TopK"] ?? "5")
    .WithEnvironment("RAG_SIMILARITY_THRESHOLD",
        builder.Configuration["Parameters:RAG:SimilarityThreshold"] ?? "0.5")
    .WithEnvironment("EMBEDDING_MODEL",
        builder.Configuration["Parameters:RAG:EmbeddingModel"] ?? "text-embedding-3-small")
    .WithEnvironment("EMBEDDING_DIMENSIONS",
        builder.Configuration["Parameters:RAG:EmbeddingDimensions"] ?? "1536")
    .WithEnvironment("EMBEDDING_DEPLOYMENT", ragEmbeddingDeployment)
    // Processing Settings
    .WithEnvironment("LARGE_DOC_THRESHOLD_KB",
        builder.Configuration["Parameters:Processing:LargeDocThresholdKb"] ?? "1500")
    .WithEnvironment("CHUNK_SIZE_CHARS",
        builder.Configuration["Parameters:Processing:ChunkSizeChars"] ?? "50000")
    .WithEnvironment("MAX_SAMPLE_PAGES",
        builder.Configuration["Parameters:Processing:MaxSamplePages"] ?? "15")
    .WithEnvironment("CONDENSED_CONTEXT_MAX_CHARS",
        builder.Configuration["Parameters:Processing:CondensedContextMaxChars"] ?? "40000")
    .WithEnvironment("AUTO_DETECT_PROCESSING_MODE",
        builder.Configuration["Parameters:Processing:AutoDetectMode"] ?? "true")
    // Automotive Claims Settings
    .WithEnvironment("AUTO_CLAIMS_ENABLED",
        builder.Configuration["Parameters:AutomotiveClaims:Enabled"] ?? "true")
    .WithEnvironment("AUTO_CLAIMS_DOC_ANALYZER",
        builder.Configuration["Parameters:AutomotiveClaims:DocAnalyzer"] ?? "autoClaimsDocAnalyzer")
    .WithEnvironment("AUTO_CLAIMS_IMAGE_ANALYZER",
        builder.Configuration["Parameters:AutomotiveClaims:ImageAnalyzer"] ?? "autoClaimsImageAnalyzer")
    .WithEnvironment("AUTO_CLAIMS_VIDEO_ANALYZER",
        builder.Configuration["Parameters:AutomotiveClaims:VideoAnalyzer"] ?? "autoClaimsVideoAnalyzer")
    .WithEnvironment("AUTO_CLAIMS_POLICIES_PATH",
        builder.Configuration["Parameters:AutomotiveClaims:PoliciesPath"] ?? "prompts/automotive-claims-policies.json")
    .WithEnvironment("VIDEO_MAX_DURATION_MINUTES",
        builder.Configuration["Parameters:AutomotiveClaims:VideoMaxDurationMinutes"] ?? "10")
    .WithEnvironment("IMAGE_MAX_SIZE_MB",
        builder.Configuration["Parameters:AutomotiveClaims:ImageMaxSizeMb"] ?? "20")
    // Mortgage Underwriting Settings
    .WithEnvironment("MORTGAGE_ENABLED",
        builder.Configuration["Parameters:MortgageUnderwriting:Enabled"] ?? "true")
    .WithEnvironment("MORTGAGE_DOC_ANALYZER",
        builder.Configuration["Parameters:MortgageUnderwriting:DocAnalyzer"] ?? "mortgageDocAnalyzer")
    .WithEnvironment("MORTGAGE_POLICIES_PATH",
        builder.Configuration["Parameters:MortgageUnderwriting:PoliciesPath"] ?? "prompts/mortgage-underwriting-policies.json")
    .WithEnvironment("OSFI_MQR_FLOOR_PCT",
        builder.Configuration["Parameters:MortgageUnderwriting:OsfiMqrFloorPct"] ?? "5.25")
    .WithEnvironment("OSFI_MQR_BUFFER_PCT",
        builder.Configuration["Parameters:MortgageUnderwriting:OsfiMqrBufferPct"] ?? "2.0")
    .WithEnvironment("GDS_LIMIT_STANDARD",
        builder.Configuration["Parameters:MortgageUnderwriting:GdsLimitStandard"] ?? "0.39")
    .WithEnvironment("TDS_LIMIT_STANDARD",
        builder.Configuration["Parameters:MortgageUnderwriting:TdsLimitStandard"] ?? "0.44")
    .WithEnvironment("LTV_LIMIT_CONVENTIONAL",
        builder.Configuration["Parameters:MortgageUnderwriting:LtvLimitConventional"] ?? "0.80")
    .WithEnvironment("LTV_LIMIT_INSURED",
        builder.Configuration["Parameters:MortgageUnderwriting:LtvLimitInsured"] ?? "0.95")
    .WithEnvironment("MAX_AMORT_INSURED",
        builder.Configuration["Parameters:MortgageUnderwriting:MaxAmortInsured"] ?? "25")
    .WithEnvironment("MAX_AMORT_UNINSURED",
        builder.Configuration["Parameters:MortgageUnderwriting:MaxAmortUninsured"] ?? "30");

    // PostgreSQL connection (when enabled)
    if (workbenchiqDb is not null)
    {
        backend
            .WithReference(workbenchiqDb)
            .WithEnvironment("DATABASE_BACKEND", "postgresql")
            .WithEnvironment("POSTGRESQL_HOST", () => workbenchiqDb.Resource.Parent.PrimaryEndpoint.Host)
            .WithEnvironment("POSTGRESQL_PORT", () => workbenchiqDb.Resource.Parent.PrimaryEndpoint.Port.ToString())
            .WithEnvironment("POSTGRESQL_DATABASE", () => workbenchiqDb.Resource.DatabaseName)
            .WithEnvironment("POSTGRESQL_USER", postgres!.Resource.UserNameParameter!)
            .WithEnvironment("POSTGRESQL_PASSWORD", postgres!.Resource.PasswordParameter!)
            .WithEnvironment("POSTGRESQL_SSL_MODE",
                builder.Configuration["Parameters:PostgreSQL:SslMode"] ?? "prefer")
            .WithEnvironment("POSTGRESQL_SCHEMA",
                builder.Configuration["Parameters:PostgreSQL:Schema"] ?? "public");
    }
    else
    {
        // Use JSON backend if PostgreSQL is not enabled
        backend.WithEnvironment("DATABASE_BACKEND",
            builder.Configuration["Parameters:DatabaseBackend"] ?? "json");
    }

    // Frontend (Next.js)
    var frontend = builder.AddNpmApp("frontend", "../../frontend", "dev")
        .WithHttpEndpoint(port: 3000, name: "http", isProxied: false)
        .WithExternalHttpEndpoints()
        .WithHttpHealthCheck("/api/health")
        .WithReference(backend)
        .WithEnvironment("API_URL", backend.GetEndpoint("http"))
        .WithEnvironment("API_KEY", apiKey)
        .WithEnvironment("AUTH_SECRET", frontendAuthSecret)
        .WithEnvironment("AUTH_USER_1", frontendAuthUser1)
        .WithEnvironment("AUTH_USER_2", frontendAuthUser2)
        .WithEnvironment("AUTH_USER_3", frontendAuthUser3)
        .WithEnvironment("AUTH_USER_4", frontendAuthUser4)
        .WithEnvironment("AUTH_USER_5", frontendAuthUser5);
}

builder.Build().Run();

// =============================================================================
// Custom KeyVaultSecretManager to add "Parameters:" prefix
// =============================================================================
// This class maps Key Vault secret names to configuration keys with the "Parameters:" prefix.
// For example: 'AzureOpenAI--Endpoint' in Key Vault becomes 'Parameters:AzureOpenAI:Endpoint'
public class PrefixKeyVaultSecretManager : KeyVaultSecretManager
{
    private readonly string _prefix;

    public PrefixKeyVaultSecretManager(string prefix)
    {
        _prefix = prefix + ":";
    }

    public override string GetKey(KeyVaultSecret secret)
    {
        // Convert Key Vault secret name (e.g., 'AzureOpenAI--Endpoint')
        // to configuration key (e.g., 'Parameters:AzureOpenAI:Endpoint')
        return _prefix + secret.Name.Replace("--", ":");
    }
}
