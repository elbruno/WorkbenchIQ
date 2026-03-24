# WorkbenchIQ Tests

This directory contains test suites for WorkbenchIQ, including unit tests, integration tests, and infrastructure verification scripts.

## Test Structure

### Python Tests (pytest)
- `test_*.py` — Unit and integration tests for the FastAPI backend
- Run with: `pytest tests/`
- Markers: `@pytest.mark.aspire`, `@pytest.mark.integration`

### PowerShell Verification Scripts
Infrastructure and deployment verification scripts for .NET Aspire orchestration.

#### `verify_aspire_phase1.ps1`
Comprehensive verification for Aspire Phase 1 (orchestration scaffold).

**Tests:**
- Project structure exists (AppHost, ServiceDefaults, .slnx)
- `dotnet build` succeeds
- Services are reachable (backend, frontend, dashboard)
- No source files modified (git integrity check)
- Frontend proxies API calls

**Usage:**
```powershell
# Full verification (starts services)
.\tests\verify_aspire_phase1.ps1

# Dry-run (no service startup)
.\tests\verify_aspire_phase1.ps1 -DryRun

# Quiet mode
.\tests\verify_aspire_phase1.ps1 -Quiet
```

**Exit Codes:**
- 0 = PASS
- 1 = FAIL

---

#### `verify_aspire_secrets.ps1`
Comprehensive verification for Aspire secrets management (User Secrets + Key Vault).

**Tests:**

**Phase 1: User Secrets Integration**
- ✅ UserSecretsId configured in .csproj
- ✅ appsettings.json has no real secrets (only empty strings/placeholders)
- ✅ appsettings.Development.json has no real API keys
- ✅ Documentation for `dotnet user-secrets` setup

**Phase 2: Azure Key Vault Configuration**
- ✅ Bicep provisions Key Vault resource
- ✅ Bicep provisions managed identity for Container Apps
- ✅ Key Vault has proper access policies/RBAC
- ✅ All sensitive parameters stored as Key Vault secrets
- ✅ Container Apps reference Key Vault secrets

**Phase 3: Secrets Leakage Detection**
- ✅ No secret patterns in committed files (hex keys, base64, connection strings)
- ✅ .gitignore excludes secrets.json, .env files
- ✅ No secrets.json in repository
- ✅ No secret files staged for commit

**Phase 4: Program.cs Integration**
- ✅ Key Vault configuration provider
- ✅ Deployment mode detection
- ✅ Secure parameter access pattern
- ✅ Empty string fallbacks (prevents crashes)

**Usage:**
```powershell
# Full verification
.\tests\verify_aspire_secrets.ps1

# Verbose output (detailed validation steps)
.\tests\verify_aspire_secrets.ps1 -Verbose

# Quiet mode (errors/warnings only)
.\tests\verify_aspire_secrets.ps1 -Quiet
```

**Exit Codes:**
- 0 = PASS (warnings acceptable for starter template)
- 1 = FAIL (secrets leaked or critical config missing)

**Secret Patterns Detected:**
- Hexadecimal API keys (32+ chars)
- Base64-encoded secrets (40+ chars)
- Azure connection strings (AccountKey, SharedAccessKey)
- Real Azure service endpoints
- OpenAI API key format

---

## CI/CD Integration

### pytest (Python tests)
```bash
# Run all tests
pytest tests/

# Run Aspire tests only
pytest tests/ -m aspire

# Run non-integration tests only
pytest tests/ -m "aspire and not integration"
```

### PowerShell Scripts (Infrastructure tests)
```powershell
# Phase 1 verification (dry-run for CI/CD)
.\tests\verify_aspire_phase1.ps1 -DryRun

# Secrets verification (always safe for CI/CD)
.\tests\verify_aspire_secrets.ps1
```

---

## Test Development Guidelines

### PowerShell Scripts
- Use helper functions: `Write-Success`, `Write-Error`, `Write-Warning`, `Write-Skip`
- Support `-Quiet` and `-Verbose` flags
- Exit code 0 = success, 1 = failure
- Track error/warning counters
- Provide actionable error messages

### pytest Tests
- Use markers: `@pytest.mark.aspire`, `@pytest.mark.integration`
- Graceful skips for connectivity tests (services may not be running)
- Clear test names: `test_{component}_{scenario}_{expected_outcome}`

---

## Prerequisites

**For Python tests:**
- Python 3.10+
- pytest: `pip install pytest`

**For PowerShell scripts:**
- .NET 10 SDK (for Aspire tests)
- PowerShell 5.1+ (Windows) or PowerShell Core 7+ (cross-platform)
- Git (for integrity checks)

---

## Troubleshooting

### pytest fails to import modules
```bash
# Add project root to PYTHONPATH
export PYTHONPATH="${PYTHONPATH}:$(pwd)"
pytest tests/
```

### PowerShell script execution policy
```powershell
# Allow script execution (current session)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# Run script
.\tests\verify_aspire_secrets.ps1
```

### Services not reachable in Phase 1 tests
- Run dry-run mode: `.\tests\verify_aspire_phase1.ps1 -DryRun`
- Start services manually: `dotnet aspire run` (from AppHost directory)
- Check ports: Backend (8000), Frontend (3000), Dashboard (15888)

---

## Test Coverage

| Test Suite | Type | Lines | Coverage |
|------------|------|-------|----------|
| `test_aspire_phase1.py` | pytest | 500+ | Phase 1 acceptance criteria |
| `verify_aspire_phase1.ps1` | PowerShell | 700+ | Infrastructure + connectivity |
| `verify_aspire_secrets.ps1` | PowerShell | 700+ | Secrets management |
| Other Python tests | pytest | — | Backend API, personas, processing |

---

## Future Enhancements

1. Add `dotnet user-secrets` setup documentation to main README
2. Unix/Linux support for PowerShell scripts
3. Integration with git pre-commit hooks
4. Performance benchmarking tests
5. Load testing for production deployment
6. Chaos engineering tests for resilience

---

**Maintained by:** Gaff (Tester)
**Last Updated:** 2026-03-25
