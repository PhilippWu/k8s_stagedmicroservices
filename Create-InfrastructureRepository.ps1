# Create-InfrastructureStructure.ps1
#
# Dieses Skript generiert NUR die Verzeichnisstruktur und die leeren Dateien
# für das zentrale 'infrastructure' GitOps-Repository.

Write-Host "🚀 Erstelle die Verzeichnisstruktur für das Infrastructure-Repository..." -ForegroundColor Green

# --- Hauptverzeichnisse ---
New-Item -ItemType Directory -Path "apps"
New-Item -ItemType Directory -Path "cluster"
New-Item -ItemType Directory -Path "docs"
New-Item -ItemType Directory -Path "scripts"

# --- Cluster-Struktur ---
New-Item -ItemType Directory -Path "cluster/bootstrap"
New-Item -ItemType Directory -Path "cluster/core-services"

# --- Apps-Struktur ---
New-Item -ItemType Directory -Path "apps/default-app"
New-Item -ItemType Directory -Path "apps/default-app/prod"
New-Item -ItemType Directory -Path "apps/default-app/test"

# --- GitHub Actions Workflows ---
New-Item -ItemType Directory -Path ".github/workflows"

Write-Host "✅ Verzeichnisstruktur erstellt." -ForegroundColor Green
Write-Host "📝 Erstelle leere Dokumentations- und Skriptdateien..." -ForegroundColor Cyan

# --- Leere Dateien erstellen ---
New-Item -ItemType File -Path "README.md"
New-Item -ItemType File -Path "docs/Setup.md"
New-Item -ItemType File -Path "docs/onboarding-service.md"
New-Item -ItemType File -Path "docs/database-strategy.md"
New-Item -ItemType File -Path "scripts/new-service.ps1"

Write-Host "✅ Alle Dateien und Ordner wurden erfolgreich erstellt." -ForegroundColor Green
Write-Host "➡️ Nächster Schritt: Füllen Sie die erstellten Dateien mit dem Inhalt aus den bereitgestellten Canvas-Dokumenten." -ForegroundColor Blue
