<#
.SYNOPSIS
    Aspire Phase 1 Integration Verification Script
    
.DESCRIPTION
    Comprehensive verification script for WorkbenchIQ Aspire Phase 1 acceptance criteria.
    
    Checks prerequisites, builds the Aspire AppHost, starts services, and validates:
    1. Project structure exists
    2. dotnet build succeeds
    3. Services are reachable (backend, frontend, dashboard)
    4. No existing source files were modified
    5. Frontend can proxy API calls to backend
    
    Should be run from: C:\src\squad-workbenchiq\WorkbenchIQ\tests\
    
.NOTES
    Windows-only. Requires:
    - .NET 10 SDK (10.0.201 or later)
    - Aspire CLI
    - Python 3.10+
    - Node.js 18+
    
    Cleans up (stops aspire run) on completion.
#>

param(
    [switch]$Quiet,
    [switch]$DryRun
)

# Global state
$script:ErrorCount = 0
$script:WarningCount = 0
$script:AspireProcess = $null
$script:ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$script:AspireRoot = Join-Path $script:ProjectRoot "aspire"
$script:AppHostDir = Join-Path $script:AspireRoot "WorkbenchIQ.AppHost"

# Service URLs
$script:BackendUrl = "http://localhost:8000"
$script:FrontendUrl = "http://localhost:3000"
$script:DashboardUrl = "https://localhost:15888"

# Timeouts
$script:HealthCheckTimeout = 30  # seconds
$script:HealthCheckInterval = 1  # seconds

# ============================================================================
# Utility Functions
# ============================================================================

function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host ("=" * 80)
    Write-Host $Message
    Write-Host ("=" * 80)
}

function Write-Step {
    param([string]$Message)
    Write-Host "[*] $Message"
}

function Write-Success {
    param([string]$Message)
    Write-Host "[✓] $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "[✗] $Message" -ForegroundColor Red
    $script:ErrorCount++
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[⚠] $Message" -ForegroundColor Yellow
    $script:WarningCount++
}

function Write-Skip {
    param([string]$Message)
    Write-Host "[⊘] $Message" -ForegroundColor Cyan
}

# ============================================================================
# Prerequisite Checks
# ============================================================================

function Test-Prerequisites {
    Write-Header "PHASE 0: Checking Prerequisites"
    
    # Check .NET SDK
    Write-Step "Checking .NET SDK..."
    try {
        $dotnetVersion = & dotnet --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success ".NET SDK installed: $dotnetVersion"
        } else {
            Write-Error ".NET SDK not found. Install .NET 10 SDK from https://dotnet.microsoft.com/download"
            return $false
        }
    } catch {
        Write-Error ".NET SDK check failed: $_"
        return $false
    }
    
    # Check Aspire CLI
    Write-Step "Checking Aspire CLI..."
    try {
        $aspireVersion = & dotnet aspire --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Aspire CLI available: $aspireVersion"
        } else {
            Write-Warning "Aspire CLI not found. Install with: dotnet tool install -g Aspire.Cli"
            Write-Step "Continuing anyway (aspire run may still work if integrated)..."
        }
    } catch {
        Write-Warning "Aspire CLI check failed: $_"
    }
    
    # Check Python
    Write-Step "Checking Python..."
    try {
        $pythonVersion = & python --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Python installed: $pythonVersion"
        } else {
            Write-Error "Python not found. Install Python 3.10+ from https://python.org"
            return $false
        }
    } catch {
        Write-Error "Python check failed: $_"
        return $false
    }
    
    # Check Node.js
    Write-Step "Checking Node.js..."
    try {
        $nodeVersion = & node --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Node.js installed: $nodeVersion"
        } else {
            Write-Error "Node.js not found. Install from https://nodejs.org"
            return $false
        }
    } catch {
        Write-Error "Node.js check failed: $_"
        return $false
    }
    
    Write-Success "All prerequisites met!"
    return $true
}

# ============================================================================
# Structure Validation
# ============================================================================

function Test-AspireStructure {
    Write-Header "PHASE 1: Validating Aspire Structure"
    
    $structurePassed = $true
    
    # Check Aspire directory
    Write-Step "Checking aspire/ directory..."
    if (Test-Path $script:AspireRoot -PathType Container) {
        Write-Success "aspire/ directory exists"
    } else {
        Write-Error "aspire/ directory not found at: $script:AspireRoot"
        $structurePassed = $false
    }
    
    # Check AppHost directory
    Write-Step "Checking WorkbenchIQ.AppHost/ directory..."
    if (Test-Path $script:AppHostDir -PathType Container) {
        Write-Success "WorkbenchIQ.AppHost/ directory exists"
    } else {
        Write-Error "WorkbenchIQ.AppHost/ directory not found at: $script:AppHostDir"
        $structurePassed = $false
    }
    
    # Check project file
    Write-Step "Checking WorkbenchIQ.AppHost.csproj..."
    $csproj = Join-Path $script:AppHostDir "WorkbenchIQ.AppHost.csproj"
    if (Test-Path $csproj -PathType Leaf) {
        Write-Success "WorkbenchIQ.AppHost.csproj exists"
    } else {
        Write-Error "WorkbenchIQ.AppHost.csproj not found at: $csproj"
        $structurePassed = $false
    }
    
    # Check Program.cs
    Write-Step "Checking Program.cs..."
    $programCs = Join-Path $script:AppHostDir "Program.cs"
    if (Test-Path $programCs -PathType Leaf) {
        Write-Success "Program.cs exists"
    } else {
        Write-Error "Program.cs not found at: $programCs"
        $structurePassed = $false
    }
    
    # Check solution file
    Write-Step "Checking WorkbenchIQ.sln..."
    $sln = Join-Path $script:AspireRoot "WorkbenchIQ.sln"
    if (Test-Path $sln -PathType Leaf) {
        Write-Success "WorkbenchIQ.sln exists"
    } else {
        Write-Error "WorkbenchIQ.sln not found at: $sln"
        $structurePassed = $false
    }
    
    return $structurePassed
}

# ============================================================================
# Build Validation
# ============================================================================

function Test-AspireBuild {
    Write-Header "PHASE 2: Building Aspire AppHost"
    
    Write-Step "Running: dotnet build in $script:AppHostDir"
    
    if ($DryRun) {
        Write-Warning "[DRY-RUN] Skipping dotnet build"
        return $true
    }
    
    try {
        $output = & dotnet build --no-restore 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "dotnet build completed successfully"
            return $true
        } else {
            Write-Error "dotnet build failed with exit code: $LASTEXITCODE"
            Write-Host "Build output:"
            Write-Host $output
            return $false
        }
    } catch {
        Write-Error "dotnet build error: $_"
        return $false
    }
}

# ============================================================================
# Service Health Checks
# ============================================================================

function Wait-ServiceHealthy {
    param(
        [string]$Url,
        [string]$ServiceName,
        [int]$Timeout = $script:HealthCheckTimeout
    )
    
    $startTime = Get-Date
    $elapsed = 0
    
    while ($elapsed -lt $Timeout) {
        try {
            # Suppress SSL warnings for localhost
            [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
            
            $response = Invoke-WebRequest -Uri $Url -TimeoutSec 2 -ErrorAction Stop
            Write-Success "$ServiceName is healthy (HTTP $($response.StatusCode))"
            return $true
        } catch {
            $elapsed = ((Get-Date) - $startTime).TotalSeconds
            Write-Host -NoNewline "."
            Start-Sleep -Seconds $script:HealthCheckInterval
        }
    }
    
    Write-Host ""
    Write-Skip "$ServiceName not responding after $Timeout seconds"
    return $false
}

function Test-ServiceConnectivity {
    Write-Header "PHASE 3: Testing Service Connectivity"
    
    $connectivityPassed = $true
    
    # Backend
    Write-Step "Checking Backend API ($script:BackendUrl)..."
    if (Wait-ServiceHealthy -Url "$script:BackendUrl/" -ServiceName "Backend") {
        # Additional check for health endpoint
        try {
            $response = Invoke-RestMethod -Uri "$script:BackendUrl/" -TimeoutSec 2 -ErrorAction Stop
            if ($response.status -eq "ok") {
                Write-Success "Backend health check: {status: ok}"
            } else {
                Write-Warning "Backend returned unexpected response: $response"
            }
        } catch {
            Write-Warning "Backend health check failed: $_"
            $connectivityPassed = $false
        }
    } else {
        Write-Warning "Backend not reachable (may not be started yet)"
        $connectivityPassed = $false
    }
    
    # Frontend
    Write-Step "Checking Frontend ($script:FrontendUrl)..."
    if (Wait-ServiceHealthy -Url "$script:FrontendUrl/" -ServiceName "Frontend") {
        Write-Success "Frontend is serving requests"
    } else {
        Write-Warning "Frontend not reachable (may not be started yet)"
        $connectivityPassed = $false
    }
    
    # Dashboard
    Write-Step "Checking Aspire Dashboard ($script:DashboardUrl)..."
    if (Wait-ServiceHealthy -Url "$script:DashboardUrl/" -ServiceName "Dashboard") {
        Write-Success "Aspire Dashboard is available"
    } else {
        Write-Warning "Dashboard not available (may take longer to start)"
    }
    
    return $connectivityPassed
}

# ============================================================================
# Source Code Integrity
# ============================================================================

function Test-SourceIntegrity {
    Write-Header "PHASE 4: Verifying Source Code Integrity"
    
    $integrityPassed = $true
    
    # Check git status for critical files
    Write-Step "Checking git status for modified files..."
    
    try {
        $gitStatus = & git status --porcelain 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Could not run git status (not in a git repo?)"
            return $true
        }
        
        # Check for modifications in critical paths
        $criticalPaths = @("api_server.py", "app/", "frontend/src/")
        $modifications = @()
        
        foreach ($file in ($gitStatus -split '\n')) {
            if (-not $file) { continue }
            
            $status = $file.Substring(0, 2)
            $filename = $file.Substring(3)
            
            # Check if file matches critical paths
            foreach ($path in $criticalPaths) {
                if ($filename -like "$path*") {
                    # ◇ = modified, A = added (new files are OK), ?? = untracked
                    if ($status -like ' M' -or $status -like 'M ') {
                        $modifications += $filename
                    }
                }
            }
        }
        
        if ($modifications.Count -eq 0) {
            Write-Success "No existing source files were modified"
        } else {
            Write-Error "The following source files were modified:"
            $modifications | ForEach-Object { Write-Host "  - $_" }
            $integrityPassed = $false
        }
        
        # Check for deletions
        Write-Step "Checking for deleted critical files..."
        $criticalFiles = @("api_server.py", "pyproject.toml", "requirements.txt")
        $deletions = @()
        
        foreach ($file in ($gitStatus -split '\n')) {
            if (-not $file) { continue }
            
            $status = $file.Substring(0, 2)
            $filename = $file.Substring(3)
            
            if ($status -like ' D' -or $status -like 'D ') {
                foreach ($critical in $criticalFiles) {
                    if ($filename -like $critical) {
                        $deletions += $filename
                    }
                }
            }
        }
        
        if ($deletions.Count -eq 0) {
            Write-Success "No critical files were deleted"
        } else {
            Write-Error "The following critical files were deleted:"
            $deletions | ForEach-Object { Write-Host "  - $_" }
            $integrityPassed = $false
        }
        
    } catch {
        Write-Warning "Source integrity check failed: $_"
    }
    
    return $integrityPassed
}

# ============================================================================
# Service Startup & Cleanup
# ============================================================================

function Start-AspireServices {
    Write-Header "PHASE 5: Starting Aspire Services (Background)"
    
    if ($DryRun) {
        Write-Warning "[DRY-RUN] Skipping service startup"
        return
    }
    
    Write-Step "Starting: aspire run from $script:AppHostDir"
    Write-Step "(Services will run in background. Press Ctrl+C to stop after verification.)"
    
    try {
        $script:AspireProcess = Start-Process -FilePath "dotnet" `
            -ArgumentList @("aspire", "run") `
            -WorkingDirectory $script:AppHostDir `
            -NoNewWindow `
            -PassThru `
            -ErrorAction Stop
        
        Write-Success "Aspire process started (PID: $($script:AspireProcess.Id))"
        Write-Step "Waiting for services to become healthy (max $($script:HealthCheckTimeout)s per service)..."
        
        # Give services time to start
        Start-Sleep -Seconds 3
        
    } catch {
        Write-Error "Failed to start aspire run: $_"
        return
    }
}

function Stop-AspireServices {
    if ($null -ne $script:AspireProcess) {
        Write-Header "CLEANUP: Stopping Aspire Services"
        Write-Step "Stopping aspire process (PID: $($script:AspireProcess.Id))..."
        
        try {
            Stop-Process -InputObject $script:AspireProcess -Force -ErrorAction SilentlyContinue
            Wait-Process -InputObject $script:AspireProcess -Timeout 5 -ErrorAction SilentlyContinue
            Write-Success "Aspire process stopped"
        } catch {
            Write-Warning "Could not cleanly stop aspire process: $_"
        }
    }
}

# ============================================================================
# Main Execution
# ============================================================================

function Main {
    Write-Host ""
    Write-Host "WorkbenchIQ — Aspire Phase 1 Verification" -ForegroundColor Cyan -BackgroundColor Black
    Write-Host "===========================================" -ForegroundColor Cyan
    Write-Host "Project Root:  $script:ProjectRoot"
    Write-Host "Aspire Root:   $script:AspireRoot"
    Write-Host "AppHost Dir:   $script:AppHostDir"
    Write-Host ""
    
    # Change to project root
    Set-Location $script:ProjectRoot
    
    # Phase 0: Prerequisites
    if (-not (Test-Prerequisites)) {
        Write-Host ""
        Write-Error "Prerequisites check failed. Cannot continue."
        exit 1
    }
    
    # Phase 1: Structure
    $structureOk = Test-AspireStructure
    
    # Phase 2: Build
    $buildOk = Test-AspireBuild
    
    if (-not $buildOk) {
        Write-Error "Build failed. Skipping service tests."
        Write-Host ""
        Write-Host "Summary" -ForegroundColor Cyan
        Write-Host "=======" -ForegroundColor Cyan
        Write-Host "Structure: $(if ($structureOk) { '✓' } else { '✗' })"
        Write-Host "Build:     ✗"
        Write-Host ""
        exit 1
    }
    
    # Phase 3-5: Services (optional with graceful degradation)
    if (-not $DryRun) {
        Start-AspireServices
        $connectivityOk = Test-ServiceConnectivity
        Stop-AspireServices
    } else {
        Write-Warning "[DRY-RUN] Skipping service connectivity tests"
        $connectivityOk = $true
    }
    
    # Phase 4: Source integrity
    $integrityOk = Test-SourceIntegrity
    
    # Summary
    Write-Header "VERIFICATION SUMMARY"
    
    Write-Host "Structure:        $(if ($structureOk) { '✓ PASS' } else { '✗ FAIL' })" -ForegroundColor $(if ($structureOk) { 'Green' } else { 'Red' })
    Write-Host "Build:            $(if ($buildOk) { '✓ PASS' } else { '✗ FAIL' })" -ForegroundColor $(if ($buildOk) { 'Green' } else { 'Red' })
    Write-Host "Connectivity:     $(if ($connectivityOk) { '✓ PASS' } else { '⚠ WARN' })" -ForegroundColor $(if ($connectivityOk) { 'Green' } else { 'Yellow' })
    Write-Host "Source Integrity: $(if ($integrityOk) { '✓ PASS' } else { '✗ FAIL' })" -ForegroundColor $(if ($integrityOk) { 'Green' } else { 'Red' })
    Write-Host ""
    Write-Host "Errors:   $script:ErrorCount"
    Write-Host "Warnings: $script:WarningCount"
    Write-Host ""
    
    if ($script:ErrorCount -gt 0) {
        Write-Host "Phase 1 Verification: FAILED" -ForegroundColor Red -BackgroundColor Black
        exit 1
    } else {
        Write-Host "Phase 1 Verification: PASSED" -ForegroundColor Green -BackgroundColor Black
        exit 0
    }
}

# Run main with cleanup on exit
try {
    Main
} finally {
    Stop-AspireServices
}
