# Test SIEM-Plus Components (No Docker Required)

Write-Host "🧪 SIEM-Plus Component Testing" -ForegroundColor Green
Write-Host "==============================" -ForegroundColor Green
Write-Host ""

$ErrorActionPreference = "Continue"
$TestsPassed = 0
$TestsFailed = 0

# Test 1: Check Prerequisites
Write-Host "Test 1: Checking Prerequisites..." -ForegroundColor Yellow
$hasGo = Get-Command go -ErrorAction SilentlyContinue
$hasRust = Get-Command cargo -ErrorAction SilentlyContinue
$hasNode = Get-Command node -ErrorAction SilentlyContinue

if ($hasGo) {
    $goVersion = go version
    Write-Host "  ✅ Go installed: $goVersion" -ForegroundColor Green
    $TestsPassed++
} else {
    Write-Host "  ❌ Go not found" -ForegroundColor Red
    $TestsFailed++
}

if ($hasRust) {
    $rustVersion = cargo --version
    Write-Host "  ✅ Rust installed: $rustVersion" -ForegroundColor Green
    $TestsPassed++
} else {
    Write-Host "  ❌ Rust not found" -ForegroundColor Red
    $TestsFailed++
}

if ($hasNode) {
    $nodeVersion = node --version
    Write-Host "  ✅ Node.js installed: $nodeVersion" -ForegroundColor Green
    $TestsPassed++
} else {
    Write-Host "  ❌ Node.js not found" -ForegroundColor Red
    $TestsFailed++
}

# Test 2: Verify Project Structure
Write-Host ""
Write-Host "Test 2: Verifying Project Structure..." -ForegroundColor Yellow
$requiredDirs = @("agent", "detect", "manager", "ui", "infra", "docs")
$allDirsExist = $true

foreach ($dir in $requiredDirs) {
    if (Test-Path $dir) {
        Write-Host "  ✅ Directory exists: $dir" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Directory missing: $dir" -ForegroundColor Red
        $allDirsExist = $false
    }
}

if ($allDirsExist) { $TestsPassed++ } else { $TestsFailed++ }

# Test 3: Check Configuration Files
Write-Host ""
Write-Host "Test 3: Checking Configuration Files..." -ForegroundColor Yellow
$configFiles = @(
    "agent\Cargo.toml",
    "detect\Cargo.toml",
    "manager\go.mod",
    "ui\package.json",
    "config\integrations.yaml",
    "config\values-prod.yaml"
)

$allConfigsExist = $true
foreach ($file in $configFiles) {
    if (Test-Path $file) {
        Write-Host "  ✅ Config exists: $file" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Config missing: $file" -ForegroundColor Red
        $allConfigsExist = $false
    }
}

if ($allConfigsExist) { $TestsPassed++ } else { $TestsFailed++ }

# Test 4: Test Agent Build
Write-Host ""
Write-Host "Test 4: Testing Agent Build..." -ForegroundColor Yellow
if ($hasRust) {
    Set-Location agent
    Write-Host "  Building agent (this may take a few minutes)..." -ForegroundColor Cyan
    $buildOutput = cargo build 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ Agent build successful" -ForegroundColor Green
        $TestsPassed++
    } else {
        Write-Host "  ❌ Agent build failed" -ForegroundColor Red
        Write-Host "  Error: $buildOutput" -ForegroundColor Red
        $TestsFailed++
    }
    Set-Location ..
} else {
    Write-Host "  ⏭️  Skipped (Rust not installed)" -ForegroundColor Yellow
}

# Test 5: Test Detection Engine Build
Write-Host ""
Write-Host "Test 5: Testing Detection Engine Build..." -ForegroundColor Yellow
if ($hasRust) {
    Set-Location detect
    Write-Host "  Building detection engine..." -ForegroundColor Cyan
    $buildOutput = cargo build 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ Detection Engine build successful" -ForegroundColor Green
        $TestsPassed++
    } else {
        Write-Host "  ❌ Detection Engine build failed" -ForegroundColor Red
        $TestsFailed++
    }
    Set-Location ..
} else {
    Write-Host "  ⏭️  Skipped (Rust not installed)" -ForegroundColor Yellow
}

# Test 6: Test Manager Build
Write-Host ""
Write-Host "Test 6: Testing Manager API Build..." -ForegroundColor Yellow
if ($hasGo) {
    Set-Location manager
    Write-Host "  Building manager..." -ForegroundColor Cyan
    go build -o manager.exe .\cmd\server\main.go 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ Manager API build successful" -ForegroundColor Green
        $TestsPassed++
    } else {
        Write-Host "  ❌ Manager API build failed" -ForegroundColor Red
        $TestsFailed++
    }
    Set-Location ..
} else {
    Write-Host "  ⏭️  Skipped (Go not installed)" -ForegroundColor Yellow
}

# Test 7: Test UI Dependencies
Write-Host ""
Write-Host "Test 7: Testing UI Dependencies..." -ForegroundColor Yellow
if ($hasNode) {
    Set-Location ui
    if (Test-Path "package.json") {
        Write-Host "  ✅ UI package.json found" -ForegroundColor Green
        $TestsPassed++
    } else {
        Write-Host "  ❌ UI package.json missing" -ForegroundColor Red
        $TestsFailed++
    }
    Set-Location ..
} else {
    Write-Host "  ⏭️  Skipped (Node.js not installed)" -ForegroundColor Yellow
}

# Test 8: Verify Documentation
Write-Host ""
Write-Host "Test 8: Verifying Documentation..." -ForegroundColor Yellow
$docFiles = @("README.md", "DEPLOYMENT_GUIDE.md", "TESTING_GUIDE.md", "PRODUCTION_READY.md")
$allDocsExist = $true

foreach ($doc in $docFiles) {
    if (Test-Path $doc) {
        Write-Host "  ✅ Documentation exists: $doc" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Documentation missing: $doc" -ForegroundColor Red
        $allDocsExist = $false
    }
}

if ($allDocsExist) { $TestsPassed++ } else { $TestsFailed++ }

# Test 9: Verify Deployment Scripts
Write-Host ""
Write-Host "Test 9: Verifying Deployment Scripts..." -ForegroundColor Yellow
$scripts = @(
    "scripts\deploy-kubernetes.ps1",
    "scripts\complete-deployment.ps1",
    "scripts\test-local.ps1"
)

$allScriptsExist = $true
foreach ($script in $scripts) {
    if (Test-Path $script) {
        Write-Host "  ✅ Script exists: $script" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Script missing: $script" -ForegroundColor Red
        $allScriptsExist = $false
    }
}

if ($allScriptsExist) { $TestsPassed++ } else { $TestsFailed++ }

# Summary
Write-Host ""
Write-Host "==============================" -ForegroundColor Green
Write-Host "Test Summary" -ForegroundColor Green
Write-Host "==============================" -ForegroundColor Green
Write-Host "Tests Passed: $TestsPassed" -ForegroundColor Green
Write-Host "Tests Failed: $TestsFailed" -ForegroundColor Red
Write-Host ""

if ($TestsFailed -eq 0) {
    Write-Host "✅ All component tests passed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Install Docker Desktop to run full integration tests"
    Write-Host "2. Run: .\scripts\test-local.ps1 (requires Docker)"
    Write-Host "3. Or deploy to Kubernetes: .\scripts\deploy-kubernetes.ps1"
} else {
    Write-Host "⚠️  Some tests failed. Please review the errors above." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Common Issues:" -ForegroundColor Cyan
    Write-Host "- Install missing prerequisites (Go, Rust, Node.js)"
    Write-Host "- Run from the project root directory"
    Write-Host "- Check internet connection for dependency downloads"
}

Write-Host ""
Write-Host "Documentation:" -ForegroundColor Cyan
Write-Host "- Full Testing Guide: TESTING_GUIDE.md"
Write-Host "- Deployment Guide: DEPLOYMENT_GUIDE.md"
Write-Host "- Production Ready: PRODUCTION_READY.md"
