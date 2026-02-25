# AGENTS.md — NOTORIA V1

## Scope
Ces instructions s'appliquent à tout le dépôt.

## Objectif du repo
Construire **NOTORIA V1**: plateforme B2B de génération vidéo avatar asynchrone (pas de live) avec orchestrateur, workers GPU, automation n8n, storage S3/MinIO et observabilité.

## Monorepo attendu
- `services/orchestrator-api`
- `services/worker-tts`
- `services/worker-video`
- `services/worker-lipsync`
- `services/worker-enhance`
- `services/worker-qa`
- `shared`
- `infra`

## Règles d'architecture
- Un `job_id` unique (UUID v4) par commande client.
- Tous les services doivent être dockerisés et démarrables via `docker compose`.
- Les interactions inter-services doivent être idempotentes.
- Les logs applicatifs doivent être structurés en JSON.
- Les métriques Prometheus doivent être exposées sur `/metrics`.
- Service Registry: persistance Postgres + migrations Alembic obligatoires.

## Standards de code
- Python 3.11+.
- API HTTP: FastAPI.
- Schémas: Pydantic.
- Nommage des files d'attente: `notoria.<domain>.<event>`.
- Style: fonctions courtes, typage explicite, constantes en MAJUSCULES.

## Tests
- Vérifier a minima la compilation Python.
- Ajouter des tests unitaires pour les comportements critiques (ex: génération `job_id`, validations schema registry).

## Sécurité / secrets
- Ne jamais committer de secrets.
- Utiliser `.env.example` pour documenter les variables.
- `auth_secret_ref` référence un secret manager; ne jamais stocker le secret brut en base.

## Livrables minimaux attendus
- `README.md` décrivant architecture, flux et démarrage.
- `infra/docker-compose.yml` pour environnement local complet.
- Spécifications OpenAPI dans `docs/openapi/`.
