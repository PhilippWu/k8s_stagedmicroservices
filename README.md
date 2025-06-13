# Infrastruktur-Repository

Dieses Repository ist die **Single Source of Truth** für die gesamte Infrastruktur und alle Anwendungs-Deployments.
Änderungen an diesem Repository werden über einen GitOps-Workflow automatisiert in den Kubernetes-Cluster ausgerollt.

## Wichtige Verzeichnisse

- `/apps`: Enthält die Deployment-Konfigurationen für jede Applikation, getrennt nach Stages (test, prod).
- `/cluster`: Beinhaltet die cluster-weite Basiskonfiguration (z.B. mit Terraform) und Core Services wie Ingress.
- `/docs`: Enthält alle wichtigen Dokumentationen zum Setup, Onboarding und zu Architektur-Entscheidungen.
- `/scripts`: Beherbergt Automatisierungs-Skripte, z.B. zum Erstellen neuer Microservices.

Lesen Sie die [Setup.md](./docs/Setup.md) für die ersten Schritte.
