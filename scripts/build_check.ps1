# Kernel MVP Standardized Build & Test Verification Script
$ErrorActionPreference = "Stop"
$env:PATH = "C:\Users\venka\dev\flutter\bin;" + $env:PATH

Write-Host "==> Running Flutter analyze on core packages..."
flutter analyze contracts app-ui audio-ai data-operations local-llm model-hub sense-ai sensor-link

Write-Host "==> Running contracts tests..."
Push-Location contracts
dart test
Pop-Location

Write-Host "==> Running audio-ai tests..."
Push-Location audio-ai
flutter test
Pop-Location

Write-Host "==> Running data-operations tests..."
Push-Location data-operations
flutter test
Pop-Location

Write-Host "==> Running app-ui tests..."
Push-Location app-ui
flutter test
Pop-Location

Write-Host "==> All packages analyzed and tested successfully!"
