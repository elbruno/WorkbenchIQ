var builder = DistributedApplication.CreateBuilder(args);

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
    .WithEnvironment("AZURE_CONTENT_UNDERSTANDING_ENDPOINT",
        builder.Configuration["Parameters:ContentUnderstanding:Endpoint"] ?? "")
    .WithEnvironment("AZURE_CONTENT_UNDERSTANDING_API_KEY",
        builder.Configuration["Parameters:ContentUnderstanding:ApiKey"] ?? "")
    .WithEnvironment("AZURE_CONTENT_UNDERSTANDING_ANALYZER_ID",
        builder.Configuration["Parameters:ContentUnderstanding:AnalyzerId"] ?? "prebuilt-documentSearch")
    .WithEnvironment("AZURE_CONTENT_UNDERSTANDING_API_VERSION",
        builder.Configuration["Parameters:ContentUnderstanding:ApiVersion"] ?? "2025-11-01")
    .WithEnvironment("AZURE_CONTENT_UNDERSTANDING_USE_AZURE_AD",
        builder.Configuration["Parameters:ContentUnderstanding:UseAzureAD"] ?? "true")
    .WithEnvironment("AZURE_CONTENT_UNDERSTANDING_COMPLETION_DEPLOYMENT",
        builder.Configuration["Parameters:ContentUnderstanding:CompletionDeployment"] ?? "")
    .WithEnvironment("AZURE_CONTENT_UNDERSTANDING_EMBEDDING_DEPLOYMENT",
        builder.Configuration["Parameters:ContentUnderstanding:EmbeddingDeployment"] ?? "")
    // Azure OpenAI (Primary)
    .WithEnvironment("AZURE_OPENAI_ENDPOINT",
        builder.Configuration["Parameters:AzureOpenAI:Endpoint"] ?? "")
    .WithEnvironment("AZURE_OPENAI_API_KEY",
        builder.Configuration["Parameters:AzureOpenAI:ApiKey"] ?? "")
    .WithEnvironment("AZURE_OPENAI_DEPLOYMENT_NAME",
        builder.Configuration["Parameters:AzureOpenAI:DeploymentName"] ?? "")
    .WithEnvironment("AZURE_OPENAI_API_VERSION",
        builder.Configuration["Parameters:AzureOpenAI:ApiVersion"] ?? "2024-10-21")
    .WithEnvironment("AZURE_OPENAI_MODEL_NAME",
        builder.Configuration["Parameters:AzureOpenAI:ModelName"] ?? "gpt-4.1")
    .WithEnvironment("AZURE_OPENAI_USE_AZURE_AD",
        builder.Configuration["Parameters:AzureOpenAI:UseAzureAD"] ?? "true")
    // Azure OpenAI (Chat-specific for Ask IQ)
    .WithEnvironment("AZURE_OPENAI_CHAT_DEPLOYMENT_NAME",
        builder.Configuration["Parameters:AzureOpenAI:ChatDeploymentName"] ?? "")
    .WithEnvironment("AZURE_OPENAI_CHAT_MODEL_NAME",
        builder.Configuration["Parameters:AzureOpenAI:ChatModelName"] ?? "")
    .WithEnvironment("AZURE_OPENAI_CHAT_API_VERSION",
        builder.Configuration["Parameters:AzureOpenAI:ChatApiVersion"] ?? "")
    // Azure OpenAI (Fallback)
    .WithEnvironment("AZURE_OPENAI_FALLBACK_ENDPOINT",
        builder.Configuration["Parameters:AzureOpenAI:FallbackEndpoint"] ?? "")
    .WithEnvironment("AZURE_OPENAI_FALLBACK_API_KEY",
        builder.Configuration["Parameters:AzureOpenAI:FallbackApiKey"] ?? "")
    .WithEnvironment("AZURE_OPENAI_FALLBACK_DEPLOYMENT_NAME",
        builder.Configuration["Parameters:AzureOpenAI:FallbackDeploymentName"] ?? "")
    .WithEnvironment("AZURE_OPENAI_FALLBACK_API_VERSION",
        builder.Configuration["Parameters:AzureOpenAI:FallbackApiVersion"] ?? "")
    .WithEnvironment("AZURE_OPENAI_FALLBACK_USE_AZURE_AD",
        builder.Configuration["Parameters:AzureOpenAI:FallbackUseAzureAD"] ?? "false")
    // Azure Storage
    .WithEnvironment("STORAGE_BACKEND",
        builder.Configuration["Parameters:StorageBackend"] ?? "local")
    .WithEnvironment("AZURE_STORAGE_ACCOUNT_NAME",
        builder.Configuration["Parameters:AzureStorage:AccountName"] ?? "")
    .WithEnvironment("AZURE_STORAGE_ACCOUNT_KEY",
        builder.Configuration["Parameters:AzureStorage:AccountKey"] ?? "")
    .WithEnvironment("AZURE_STORAGE_CONTAINER_NAME",
        builder.Configuration["Parameters:AzureStorage:ContainerName"] ?? "")
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
    .WithEnvironment("API_KEY",
        builder.Configuration["Parameters:ApiKey"] ?? "")
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
    .WithEnvironment("EMBEDDING_DEPLOYMENT",
        builder.Configuration["Parameters:RAG:EmbeddingDeployment"] ?? "")
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
        .WithEnvironment("API_KEY",
            builder.Configuration["Parameters:ApiKey"] ?? "")
        .WithEnvironment("AUTH_SECRET",
            builder.Configuration["Parameters:Frontend:AuthSecret"] ?? "")
        .WithEnvironment("AUTH_USER_1",
            builder.Configuration["Parameters:Frontend:AuthUser1"] ?? "")
        .WithEnvironment("AUTH_USER_2",
            builder.Configuration["Parameters:Frontend:AuthUser2"] ?? "")
        .WithEnvironment("AUTH_USER_3",
            builder.Configuration["Parameters:Frontend:AuthUser3"] ?? "")
        .WithEnvironment("AUTH_USER_4",
            builder.Configuration["Parameters:Frontend:AuthUser4"] ?? "")
        .WithEnvironment("AUTH_USER_5",
            builder.Configuration["Parameters:Frontend:AuthUser5"] ?? "");
}

builder.Build().Run();
