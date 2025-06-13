# Datenbank-Strategie (MongoDB & PostgreSQL)

Diese Strategie definiert, wie wir mit persistenten Daten für unsere Microservices umgehen. Die oberste Regel lautet: **Datenbanken sind zustandsbehaftet (stateful) und müssen mit besonderer Sorgfalt behandelt werden.**

## Grundprinzip: Getrennte Datenbanken pro Service und Stage

Jeder Service, der eine Datenbank benötigt, erhält seine eigene, dedizierte Datenbankinstanz. Wir teilen keine Datenbanken zwischen Services. Ebenso erhält jede Stage (`Test`, `Prod`) ihre eigene, vollständig isolierte Datenbank. Eine `Test`-Anwendung darf **niemals** auf eine `Prod`-Datenbank zugreifen.

### Strategie für `EW` und `Test`-Stages

Für Entwicklungs- und Testumgebungen setzen wir auf **In-Cluster-Datenbanken**.

- **Technologie**: Wir verwenden die offiziellen Helm-Charts von [Bitnami](https://bitnami.com/stacks/helm) für PostgreSQL und MongoDB.
- **Deployment**: Die Datenbank wird als `StatefulSet` innerhalb des jeweiligen App-Namespaces (z.B. in `app-a-test`) bereitgestellt.
- **Vorteile**:
    - **Kostengünstig**: Läuft auf der vorhandenen Kubernetes-Infrastruktur.
    - **Einfach**: Schnelle und einfache Bereitstellung per Helm.
    - **Ephemeral**: Daten können leicht zurückgesetzt werden, was ideal für Tests ist.
- **Nachteile**:
    - **Keine Produktionsreife**: Backups, Hochverfügbarkeit und Skalierung erfordern erheblichen manuellen Aufwand.

### Strategie für die `Prod`-Stage

Für die Produktionsumgebung setzen wir ausschließlich auf **verwaltete Cloud-Datenbankdienste (Managed Databases)**.

- **Technologie**:
    - **PostgreSQL**: Amazon RDS for PostgreSQL, Azure Database for PostgreSQL, Google Cloud SQL.
    - **MongoDB**: MongoDB Atlas, Amazon DocumentDB.
- **Provisionierung**: Die Datenbanken werden via **Terraform** in unserem `infrastructure`-Repository (`/cluster/bootstrap/databases.tf`) provisioniert. Dies stellt sicher, dass ihre Konfiguration versioniert und reproduzierbar ist.
- **Secrets Management**:
    - Verbindungsdaten (Host, User, Passwort) werden **NIEMALS** in Git eingecheckt.
    - Sie werden im Secret Manager des jeweiligen Cloud-Providers gespeichert (z.B. AWS Secrets Manager, Azure Key Vault).
    - Die Kubernetes-Pods der Anwendung erhalten zur Laufzeit über einen speziellen Injektor (z.B. External Secrets Operator) Zugriff auf diese Secrets.
- **Vorteile**:
    - **Hochverfügbarkeit & Skalierbarkeit**: Wird vom Cloud-Provider garantiert.
    - **Automatische Backups**: Tägliche Backups und Point-in-Time-Recovery sind Standard.
    - **Sicherheit**: Der Provider kümmert sich um Sicherheitsupdates und Konfiguration.
