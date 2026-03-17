# 🔐 ProjetLAMP — Pipeline DevSecOps CI/CD

> Stack LAMP conteneurisée avec pipeline CI/CD sécurisé intégrant SAST, scan CVE et DAST.  
> **Pr. Noureddine GRASSA — ISET Sousse**

---

## 📋 Table des matières

- [Architecture](#architecture)
- [Stack technique](#stack-technique)
- [Structure du projet](#structure-du-projet)
- [Pipeline CI/CD](#pipeline-cicd)
- [Détection intelligente des changements](#détection-intelligente-des-changements)
- [Secrets GitHub requis](#secrets-github-requis)
- [Lancement local (WSL)](#lancement-local-wsl)
- [Rapports de sécurité](#rapports-de-sécurité)

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      GitHub Actions                         │
│                                                             │
│  push/PR sur master                                         │
│        │                                                    │
│        ▼                                                    │
│  ┌─────────┐    ┌──────────┐   ┌──────────┐                │
│  │  BUILD  │───▶│SAST-CODE │   │SAST-IMAGE│                │
│  │(si modif│    │(Semgrep) │   │(Trivy)   │                │
│  │app/ db/)│    └────┬─────┘   └────┬─────┘                │
│  └────┬────┘         └──────┬───────┘                      │
│       │                     ▼                              │
│       │              ┌─────────────┐                       │
│       │              │PUSH DockerHub│                       │
│       │              └──────┬──────┘                       │
│       │                     ▼                              │
│       │              ┌─────────────┐                       │
│       │              │   DEPLOY    │                       │
│       │              └──────┬──────┘                       │
│       │                     ▼                              │
│       │         ┌──────────────────────┐                   │
│       │         │  DAST ZAP Baseline   │                   │
│       │         └──────────┬───────────┘                   │
│       │                    ▼                               │
│       │         ┌──────────────────────┐                   │
│       │         │   DAST ZAP Full      │                   │
│       │         └──────────────────────┘                   │
│       │                                                     │
│       └── (aucun changement app/db → pipeline stoppé) ─────┘
└─────────────────────────────────────────────────────────────┘
```

---

## Stack technique

| Composant | Technologie |
|-----------|-------------|
| Serveur web | Apache 2 + PHP |
| Base de données | MySQL |
| Conteneurisation | Docker + Docker Compose |
| Registry | DockerHub |
| CI/CD | GitHub Actions |
| SAST code | Semgrep (OWASP Top 10, secrets, PHP) |
| SAST image | Trivy (CVE CRITICAL/HIGH) |
| DAST | OWASP ZAP (Baseline + Full Scan) |
| Résultats sécurité | GitHub Security (onglet Security → Code scanning) |

---

## Structure du projet

```
projetLAMP/
├── app/
│   ├── Dockerfile          # Image Apache + PHP
│   └── ...                 # Code source PHP
├── db/
│   ├── Dockerfile          # Image MySQL
│   └── ...                 # Scripts SQL
├── .zap/
│   └── rules.tsv           # Règles ZAP personnalisées
├── .github/
│   └── workflows/
│       └── deploy.yml      # Pipeline CI/CD complet
├── docker-compose.yml      # Orchestration locale et CI
├── .env                    # Variables locales (non commité)
└── README.md
```

---

## Pipeline CI/CD

Le pipeline comprend **7 jobs** exécutés séquentiellement selon les dépendances :

### Job 1 — BUILD
- Détecte si des fichiers dans `app/` ou `db/` ont été modifiés
- Si **oui** : build des images Docker avec tag `SHA-7` et upload en artifact
- Si **non** : tous les jobs suivants sont **skippés automatiquement**

### Job 2 — SAST Code (Semgrep)
Analyse statique du code source avec les règles :
- `p/owasp-top-ten` — vulnérabilités OWASP
- `p/secrets` — secrets exposés dans le code
- `p/docker` — mauvaises pratiques Dockerfile
- `p/php` — vulnérabilités PHP spécifiques

### Job 3 — SAST Image (Trivy)
Scan des images Docker construites à la recherche de CVE de sévérité **CRITICAL** et **HIGH**.  
Deux scans indépendants : `projetlamp-webapp` et `projetlamp-db`.

### Job 4 — Push DockerHub
Push des images taguées vers DockerHub uniquement après validation SAST.

### Job 5 — Deploy
Déploiement via `docker-compose pull && docker-compose up -d` avec les variables `IMAGE_TAG` et `DOCKER_USERNAME` injectées.

### Job 6 — DAST ZAP Baseline
Scan rapide OWASP ZAP ciblant les vulnérabilités passives (sans interaction active).  
La stack est redémarrée sur le runner isolé avant le scan.

### Job 7 — DAST ZAP Full Scan
Scan complet OWASP ZAP avec crawl actif de l'application.  
Génère un rapport HTML et un fichier SARIF uploadé dans GitHub Security.

---

## Détection intelligente des changements

Le pipeline ne se déclenche **que si `app/` ou `db/` sont modifiés** :

```
Commit sur master
        │
        ▼
git diff HEAD~1 HEAD | grep '^(app/|db/)'
        │
   ┌────┴────┐
  OUI       NON
   │         │
   ▼         ▼
Pipeline  Arrêt après
complet   job build
(7 jobs)  (1 job)
```

Cela évite de rebuilder, rescanner et redéployer pour des modifications de documentation, de configuration CI ou de fichiers non applicatifs.

---

## Secrets GitHub requis

À configurer dans **Settings → Secrets and variables → Actions** :

| Secret | Description |
|--------|-------------|
| `DOCKER_USERNAME` | Identifiant DockerHub |
| `DOCKER_PASSWORD` | Mot de passe ou token DockerHub |
| `SEMGREP_APP_TOKEN` | Token API Semgrep (optionnel) |

---

## Lancement local (WSL)

### Prérequis
- Docker Desktop avec intégration WSL2 activée
- Docker Compose installé

### Démarrage

```bash
# 1. Cloner le projet
git clone https://github.com/<TON_USER>/projetLAMP.git
cd projetLAMP

# 2. Créer le fichier .env
cat > .env << EOF
IMAGE_TAG=local
DOCKER_USERNAME=grassa77
EOF

# 3. Lancer la stack
docker-compose up -d

# 4. Vérifier les conteneurs
docker-compose ps

# 5. Accéder à l'application
# Depuis Windows : http://localhost
# Depuis WSL     : curl http://localhost
```

### Arrêt

```bash
docker-compose down
```

---

## Rapports de sécurité

Les résultats des scans sont disponibles dans GitHub à deux endroits :

**GitHub Security (onglet Code scanning)**
- Résultats Semgrep (SAST code)
- Résultats Trivy webapp et db (CVE)
- Résultats OWASP ZAP Full Scan (DAST)

**GitHub Actions Artifacts** (téléchargeables depuis chaque run)
- `zap-baseline-report` → rapport HTML ZAP Baseline
- `zap-full-report` → rapport HTML ZAP Full Scan

---

## Auteur

**Pr. Noureddine GRASSA**  
Senior Lecturer — Département Informatique  
ISET Sousse, Tunisie  
🌐 [n.grassa.free.fr](http://n.grassa.free.fr)
