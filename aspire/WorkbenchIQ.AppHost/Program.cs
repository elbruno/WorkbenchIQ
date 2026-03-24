var builder = DistributedApplication.CreateBuilder(args);

// Azure Resources (connection references — not provisioned by Aspire)
var contentUnderstandingEndpoint = builder.AddConnectionString("ContentUnderstanding");
var openaiEndpoint = builder.AddConnectionString("AzureOpenAI");
var storageAccount = builder.AddConnectionString("AzureBlobStorage");

// Backend API (Python/FastAPI)
var backend = builder.AddPythonApp("backend-api", "../../", "api_server.py")
    .WithHttpEndpoint(port: 8000, name: "http")
    .WithExternalHttpEndpoints()
    .WithEnvironment("AZURE_CONTENT_UNDERSTANDING_ENDPOINT",
        () => builder.Configuration["ConnectionStrings:ContentUnderstanding:Endpoint"] ?? "")
    .WithEnvironment("AZURE_OPENAI_ENDPOINT",
        () => builder.Configuration["ConnectionStrings:AzureOpenAI:Endpoint"] ?? "")
    .WithEnvironment("STORAGE_BACKEND",
        builder.Configuration["Parameters:StorageBackend"] ?? "local")
    .WithEnvironment("UW_APP_STORAGE_ROOT", "data");

// Frontend (Next.js via npm)
var frontend = builder.AddNpmApp("frontend", "../../frontend", "dev")
    .WithHttpEndpoint(port: 3000, name: "http", isProxied: false)
    .WithExternalHttpEndpoints()
    .WithReference(backend)
    .WithEnvironment("API_URL", backend.GetEndpoint("http"))
    .WithEnvironment("API_KEY",
        builder.Configuration["Parameters:ApiKey"] ?? "dev-api-key");

builder.Build().Run();
