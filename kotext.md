# Projektkontext: Architektur für eine gestagete Microservice-Plattform

Dieses Dokument fasst die konzeptionellen und architektonischen Entscheidungen für den Aufbau einer skalierbaren, sicheren und wartbaren Microservice-Plattform zusammen.

## 1. Grundlegendes Ziel

Das Ziel ist die Schaffung einer robusten Infrastruktur für die Entwicklung und den Betrieb mehrerer Applikationen, die aus einzelnen Microservices bestehen. Ein zentraler Aspekt ist die klare Trennung von Entwicklungs-, Test- und Produktionsumgebungen, um schnelle und sichere Release-Zyklen zu ermöglichen.

## 2. Architektur und Repository-Struktur (Multi-Repo & GitOps)

Wir verfolgen einen **Multi-Repo-Ansatz**, bei dem die Zuständigkeiten klar getrennt sind:

* **Service-Repositories**: Jeder einzelne Microservice (z.B. `user-service`) lebt in seinem eigenen Repository. Dies ermöglicht autonomen Teams, ihre Services unabhängig voneinander zu entwickeln, zu testen und zu versionieren.

* **Infrastructure-Repository**: Ein zentrales Repository dient als **Single Source of Truth** für die gesamte Infrastruktur und die Deployments. Änderungen an der Infrastruktur oder an den Anwendungsversionen werden hier deklarativ beschrieben und mittels **GitOps** automatisiert umgesetzt.

## 3. Staging-Konzept

Die Plattform ist in logische Stages unterteilt, um den gesamten Lebenszyklus einer Anwendung abzudecken. Mit Ausnahme der `EW`-Stage werden alle Umgebungen als dedizierte **Namespaces** in einem einzigen Kubernetes-Cluster betrieben.

* **EW (Entwicklungs-Stage)**:

    * **Zweck**: Schnelle, iterative Entwicklung und Debugging durch einzelne Entwickler.

    * **Umsetzung**: Ein hybrider Ansatz. Entwickler arbeiten lokal auf ihren Notebooks in **VS Code Dev Containern**, die eine konsistente Toolchain sicherstellen. Mit **Telepresence** wird der lokal laufende Service-Container in das Netzwerk der `Test`-Stage im Kubernetes-Cluster integriert. Dies ermöglicht die Entwicklung auf jedem beliebigen Branch im Kontext der gesamten Anwendung, ohne den Cluster zu belasten.

* **Test-Stage**:

    * **Zweck**: Vollständige Systemtests, Integrationstests und Qualitätssicherung der gesamten Applikation.

    * **Umsetzung**: Ein dedizierter Namespace pro Applikation (z.B. `app-a-test`).

    * **Deployment-Trigger**: Automatisch bei jedem Commit/Push auf den `main`-Branch eines Service- oder Deployment-Repos.

* **Prod-Stage**:

    * **Zweck**: Die produktive, für Endkunden erreichbare Umgebung. Stabilität, Sicherheit und Performance haben hier höchste Priorität.

    * **Umsetzung**: Ein hochgradig gesicherter, separater Namespace pro Applikation (z.B. `app-a-prod`).

    * **Deployment-Trigger**: **Manuell** oder durch die Erstellung eines offiziellen **GitHub Release** (Git-Tag). Deployments in die Produktion sind immer ein bewusster, kontrollierter Akt.

* **Core-Services-Stage**:

    * **Zweck**: Bereitstellung von zentraler, cluster-weiter Infrastruktur, die von allen Applikationen und Stages genutzt wird.

    * **Umsetzung**: Ein eigener `core-services`-Namespace.

    * **Komponenten**: Ingress Controller (Proxy), cert-manager (SSL), ExternalDNS (DNS-Verwaltung), Observability-Stack (Monitoring, Logging).

## 4. Workflows und Automatisierung

* **CI (Continuous Integration)**: Findet in jedem Service-Repository statt. Bei jedem Push wird der Code getestet, ein Docker-Image gebaut und in eine Container-Registry (z.B. GitHub Packages) gepusht.

* **CD (Continuous Deployment)**: Wird vom `infrastructure`-Repository aus gesteuert. Änderungen an den Deployment-Konfigurationen (z.B. eine neue Image-Version) werden per Pull Request eingebracht und nach dem Merge automatisch von einer GitHub Action im entsprechenden Stage-Namespace ausgerollt.

* **Service Onboarding**: Die Erstellung eines neuen Microservice-Repositorys ist durch ein PowerShell-Skript (`scripts/new-service.ps1`) automatisiert. Dieses Skript erstellt ein standardisiertes Repository inklusive Dockerfile, CI-Pipeline und Dev-Container-Konfiguration.

## 5. Technologiestack (Standardisierung)

* **Orchestrierung**: Kubernetes

* **Infrastructure as Code (IaC)**: Terraform (für Cloud-Ressourcen wie den K8s-Cluster selbst)

* **Deployment-Management**: Helm

* **CI/CD**: GitHub Actions

* **Lokale Entwicklung**: VS Code Dev Containers & Telepresence

* **DNS & Proxy**: ExternalDNS, cert-manager, NGINX Ingress Controller

## 6. Datenbank-Strategie

* **Grundprinzip**: Strikte Trennung von Datenbanken pro Service und pro Stage.

* **Test-Stage**: Kostengünstige, einfach bereitzustellende **In-Cluster-Datenbanken**, verwaltet über Helm-Charts (z.B. von Bitnami).

* **Prod-Stage**: Ausschließlich hochverfügbare, sichere **verwaltete Cloud-Datenbankdienste** (z.B. AWS RDS, MongoDB Atlas), provisioniert über Terraform. Secrets werden sicher über einen Secret Manager des Cloud-Providers verwaltet.