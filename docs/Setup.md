# Setup-Anleitung für die Infrastruktur

Dieses Dokument beschreibt die Schritte, um die gesamte Infrastruktur von Grund auf neu aufzusetzen.

## 0. Voraussetzungen

Stellen Sie sicher, dass die folgenden Werkzeuge installiert und konfiguriert sind:
- `git`: Zur Versionskontrolle.
- `gh`: Die GitHub CLI, authentifiziert bei Ihrer Organisation.
- `powershell`: Für die Ausführung der Skripte.
- `kubectl`: Zur Interaktion mit dem Kubernetes-Cluster.
- `helm`: Für das Paketmanagement in Kubernetes.
- `terraform`: Für das Provisionieren der Cloud-Infrastruktur.
- `telepresence`: Für den lokalen Entwicklungs-Workflow (EW-Stage).

## 1. Manuelles GitHub-Setup

Diese Schritte müssen manuell in GitHub durchgeführt werden:

1.  **Organisation erstellen**: Falls noch nicht geschehen, erstellen Sie eine GitHub-Organisation.
2.  **Repository erstellen**: Erstellen Sie dieses `infrastructure`-Repository in Ihrer Organisation und pushen Sie den Inhalt dieses Verzeichnisses.
3.  **Secrets konfigurieren**: Navigieren Sie zu `Settings > Secrets and variables > Actions` und fügen Sie folgende Repository-Secrets hinzu:
    - `KUBE_CONFIG`: Base64-enkodierter Inhalt Ihrer Kubeconfig-Datei mit Admin-Rechten für den Cluster.
    - `CLOUDFLARE_API_TOKEN`: Ihr API-Token von Cloudflare für ExternalDNS.
    - `GH_TOKEN`: Ein GitHub Personal Access Token mit `repo`-Rechten, damit die Skripte neue Repositories erstellen können.

## 2. Cloud-Infrastruktur aufbauen (Terraform)

Die Kerninfrastruktur (Kubernetes-Cluster, VPCs etc.) wird mit Terraform verwaltet.

1.  Navigieren Sie in das Verzeichnis `/cluster/bootstrap`.
2.  Passen Sie die `main.tf` und `terraform.tfvars` an Ihre Cloud-Anforderungen (z.B. AWS, Azure, GCP) an. (Platzhalterdateien müssen noch erstellt werden).
3.  Führen Sie die folgenden Befehle aus:
    `terraform init`
    `terraform plan`
    `terraform apply`
4.  Nach erfolgreicher Anwendung ist Ihr Kubernetes-Cluster bereit. Konfigurieren Sie `kubectl`, um auf den neuen Cluster zuzugreifen.

## 3. Core Services installieren

Die Basisdienste werden über Helm-Charts installiert. Konfigurationen liegen in `/cluster/core-services`.

```bash
# Beispiel für die Installation des NGINX Ingress Controllers
helm repo add ingress-nginx [https://kubernetes.github.io/ingress-nginx](https://kubernetes.github.io/ingress-nginx)
helm repo update
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace core-services --create-namespace \
  -f cluster/core-services/ingress-nginx-values.yaml
```
Wiederholen Sie dies für `cert-manager`, `ExternalDNS` und weitere Core Services.

## 4. Anwendungs-Deployments (GitOps-Workflow)

Deployments werden durch Commits in dieses Repository ausgelöst. Die GitHub Actions in `.github/workflows` sind dafür verantwortlich. Ein typischer Workflow ist:

1.  Ein Entwickler möchte eine neue Version eines Service deployen.
2.  Er erstellt einen Pull Request, der die Image-Version in der relevanten `values.yaml`-Datei unter `/apps/<app-name>/<stage>/` ändert.
3.  Nach dem Merge des PRs startet die GitHub Action und führt `helm upgrade` für die entsprechende App/Stage aus.

## 5. Entwickler-Workflow (EW-Stage)

Die `EW`-Stage findet lokal auf den Entwickler-Notebooks statt. Der Prozess ist in der [Service Onboarding Anleitung](./onboarding-service.md) detailliert beschrieben und nutzt Telepresence, um lokale Services mit der `Test`-Stage im Cluster zu verbinden.
