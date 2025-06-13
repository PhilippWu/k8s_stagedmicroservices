# Anleitung: Einen neuen Microservice erstellen und integrieren

Dieses Dokument beschreibt den automatisierten Prozess zur Erstellung eines neuen Microservice-Repositorys und dessen Integration in unsere Systemlandschaft.

## Prozess

Der gesamte Prozess wird durch das PowerShell-Skript `new-service.ps1` gesteuert.

### Voraussetzungen
- Sie müssen die [GitHub CLI (`gh`)](https://cli.github.com/) installiert und sich mit `gh auth login` angemeldet haben.

### Ausführung
1.  Öffnen Sie eine PowerShell-Konsole im Hauptverzeichnis des `infrastructure`-Repositorys.
2.  Führen Sie das Skript mit den erforderlichen Parametern aus:

    ```powershell
    ./scripts/new-service.ps1 -serviceName "mein-neuer-service" -applicationName "default-app" -orgName "<DEINE_GITHUB_ORG>"
    ```

### Was das Skript tut
1.  **GitHub Repository erstellen**: Erstellt ein neues, leeres Repository in Ihrer Organisation.
2.  **Struktur klonen und erstellen**: Klont das leere Repo und erstellt eine Standardstruktur mit:
    - `src/`: Für Ihren Quellcode.
    - `Dockerfile`: Eine Vorlage zur Containerisierung Ihrer App.
    - `.devcontainer/`: Konfiguration für eine konsistente Entwicklungsumgebung in VS Code.
    - `.github/workflows/ci.yml`: Eine GitHub Action zum Bauen, Testen und Pushen des Docker-Images in die GitHub Container Registry.
3.  **Initialer Commit**: Pusht die Standarddateien in das neue Repository.
4.  **Integration im Infrastructure-Repo**: Erstellt eine Platzhalter-Konfigurationsdatei unter `/apps/<applicationName>/`, um den neuen Service im Deployment-Prozess bekannt zu machen.

### Nächste Schritte für den Entwickler
1.  Klonen Sie das neue Service-Repository.
2.  Füllen Sie den `src/`-Ordner mit Ihrer Anwendungslogik.
3.  Passen Sie bei Bedarf den `Dockerfile` und die `ci.yml` an.
4.  Beginnen Sie mit der Entwicklung gemäß dem `EW`-Workflow (lokal mit Telepresence).
