# new-service.ps1
param(
    [Parameter(Mandatory=$true)]
    [ValidatePattern("^[a-zA-Z0-9\-]+$")]
    [string]$serviceName,

    [Parameter(Mandatory=$true)]
    [ValidatePattern("^[a-zA-Z0-9\-]+$")]
    [string]$applicationName,

    [Parameter(Mandatory=$true)]
    [ValidatePattern("^[a-zA-Z0-9\-]+$")]
    [string]$orgName
)

# Fehlerbehandlung aktivieren
$ErrorActionPreference = "Stop"

# Validate prerequisites
function Test-Prerequisites {
    # Test if gh CLI is available
    try {
        $null = Get-Command gh -ErrorAction Stop
    } catch {
        throw "GitHub CLI (gh) ist nicht installiert oder nicht im PATH verfügbar. Bitte installieren Sie es zuerst."
    }
      # Test if gh is authenticated
    try {
        gh auth status 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "GitHub CLI ist nicht authentifiziert. Bitte führen Sie 'gh auth login' aus."
        }
    } catch {
        throw "GitHub CLI Authentifizierung fehlgeschlagen: $_"
    }
    
    # Test if git is available
    try {
        $null = Get-Command git -ErrorAction Stop
    } catch {
        throw "Git ist nicht installiert oder nicht im PATH verfügbar."
    }
}

Write-Host "🔍 Überprüfe Voraussetzungen..." -ForegroundColor Cyan
Test-Prerequisites

Write-Host "🚀 Starte Erstellung des neuen Microservice: '$serviceName' für die Applikation '$applicationName'" -ForegroundColor Green

# --- Schritt 1: GitHub Repository erstellen ---
Write-Host "   -> Erstelle GitHub Repository '$orgName/$serviceName'..." -ForegroundColor Yellow
try {
    $result = gh repo create "$orgName/$serviceName" --public --clone 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "GitHub CLI command failed: $result"
    }
} catch {
    Write-Error "Fehler beim Erstellen des GitHub Repos. Ist die 'gh' CLI installiert und authentifiziert? Error: $_"
    return
}

# --- Schritt 2: Standard-Dateistruktur und -Inhalte erstellen ---
$repoPath = "./$serviceName"
if (-not (Test-Path $repoPath)) {
    Write-Error "Repository path '$repoPath' was not created. GitHub clone might have failed."
    return
}
Set-Location $repoPath

Write-Host "   -> Erstelle Standard-Verzeichnisse..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path "src" -Force
New-Item -ItemType Directory -Path ".github/workflows" -Force
New-Item -ItemType Directory -Path ".devcontainer" -Force

Write-Host "   -> Generiere Standarddateien..." -ForegroundColor Yellow

# Dockerfile
@"
# Use an official Node.js runtime as a parent image
FROM node:18-alpine
# Set the working directory in the container
WORKDIR /usr/src/app
# Copy package.json and package-lock.json
COPY package*.json ./
# Install any needed packages
RUN npm install
# Bundle app source
COPY . .
# Make port 3000 available to the world outside this container
EXPOSE 3000
# Define environment variable
ENV NAME World
# Run the app when the container launches
CMD [ "node", "src/index.js" ]
"@ | Set-Content -Path "Dockerfile" -Encoding utf8

# .devcontainer/devcontainer.json
@"
{
    "name": "Node.js Dev Container",
    "image": "mcr.microsoft.com/devcontainers/javascript-node:0-18",
    "forwardPorts": [3000],
    "postCreateCommand": "npm install",
    "customizations": {
        "vscode": {
            "extensions": [
                "dbaeumer.vscode-eslint"
            ]
        }
    }
}
"@ | Set-Content -Path ".devcontainer/devcontainer.json" -Encoding utf8

# .github/workflows/ci.yml
@"
name: Build and Push Docker Image
on:
  push:
    branches:
      - main
    tags:
      - 'v*.*.*'

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
      - name: Checkout repository
        uses: actions/checkout@v3

      - name: Log in to the Container registry
        uses: docker/login-action@v2
        with:
          registry: ghcr.io
          username: "`${{ github.actor }}"
          password: "`${{ secrets.GITHUB_TOKEN }}"

      - name: Build and push Docker image
        uses: docker/build-push-action@v4
        with:
          context: .
          push: true
          tags: "ghcr.io/$($orgName)/$($serviceName):`${{ github.sha }}"
"@ | Set-Content -Path ".github/workflows/ci.yml" -Encoding utf8

# Leere index.js und package.json
"console.log('Hello from $serviceName!');" | Set-Content -Path "src/index.js" -Encoding utf8

$packageJsonContent = @{
    name = $serviceName
    version = "1.0.0"
    main = "src/index.js"
    scripts = @{
        start = "node src/index.js"
    }
} | ConvertTo-Json -Depth 3
$packageJsonContent | Set-Content -Path "package.json" -Encoding utf8

# --- Schritt 3: Initialen Commit pushen ---
Write-Host "   -> Pushe initiale Dateien nach GitHub..." -ForegroundColor Yellow
try {
    git add .
    git commit -m "feat: initial structure for $serviceName"
    git push origin main
    if ($LASTEXITCODE -ne 0) {
        throw "Git push failed"
    }
} catch {
    Write-Error "Fehler beim Pushen der Dateien: $_"
    Set-Location ..
    return
}

# Zurück zum infrastructure-Repo
Set-Location ..
try {
    Remove-Item -Recurse -Force $repoPath -ErrorAction SilentlyContinue
} catch {
    Write-Warning "Konnte temporäres Repository-Verzeichnis nicht löschen: $_"
}

# --- Schritt 4: Integration im Infrastructure-Repo ---
Write-Host "   -> Erstelle Platzhalter-Konfiguration im 'apps' Verzeichnis..." -ForegroundColor Yellow
$configPath = "./apps/$applicationName/test/services"
New-Item -ItemType Directory -Path $configPath -Force -ErrorAction SilentlyContinue

# YAML-Konfiguration ohne PowerShell-Variablen-Interpolation
$yamlContent = @"
# Platzhalter für $serviceName in der Test-Stage
# In Helm würde dies in die values-test.yaml der App einfliessen
$serviceName`:
  replicaCount: 1
  image:
    repository: ghcr.io/$orgName/$serviceName
    tag: latest # In Test kann 'latest' oder ein Commit-SHA verwendet werden
"@
$yamlContent | Set-Content -Path "$configPath/$serviceName.yaml" -Encoding utf8

Write-Host "✅ Fertig! Der Service '$serviceName' wurde erstellt und grundlegend integriert." -ForegroundColor Green
Write-Host "Nächste Schritte für den Entwickler:" -ForegroundColor Cyan
Write-Host "  1. Repository klonen: git clone https://github.com/$orgName/$serviceName.git" -ForegroundColor White
Write-Host "  2. Mit der Entwicklung in 'src/' beginnen" -ForegroundColor White
Write-Host "  3. GitHub Actions CI/CD pipeline ist bereits konfiguriert" -ForegroundColor White
