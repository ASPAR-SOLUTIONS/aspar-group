# ASPAR Franchise — Pipeline Social Media Automatisé

Pipeline social media entièrement automatisé pour ASPAR Franchise, piloté par une architecture multi-agents Claude Code.

## Architecture

```
master-pipeline.sh
       │
       ▼
  CLAUDE.md (orchestrateur)
       │
       ├── 1. agent-content    → Notion DB → Textes (LinkedIn/IG/FB/TikTok)
       ├── 2. agent-visual     → Genspark/Canva → 5 Slides (#1B2A4A + #F47920)
       ├── 3. agent-pdf        → Puppeteer → PDF multi-formats
       ├── 4. agent-publish    → n8n MCP → Buffer → Twin webhook
       └── 5. agent-analytics  → Stats → Notion → Rapport Gmail
```

## Identité ASPAR

- **Marque** : ASPAR Franchise — Majdi (fondateur)
- **Couleurs** : `#1B2A4A` (fond) + `#F47920` (accent)
- **Plateformes** : LinkedIn · Instagram · Facebook · TikTok · Pinterest
- **n8n MCP** : `https://notoria.app.n8n.cloud/mcp-server/http`

## Orchestration — Séquence automatique

L'orchestrateur exécute les 5 agents **en séquence stricte**. Chaque agent doit terminer avec succès avant de lancer le suivant. Le statut Notion est le signal de passage entre agents.

### Conditions de passage

| Étape | Agent | Condition démarrage | Signal de fin |
|-------|-------|--------------------|--------------:|
| 1 | agent-content | Entrée Notion statut "À rédiger" | Statut → "Texte prêt" |
| 2 | agent-visual | Statut "Texte prêt" | Statut → "Visuels prêts" |
| 3 | agent-pdf | Statut "Visuels prêts" | Statut → "PDF prêt" |
| 4 | agent-publish | Statut "PDF prêt" | Statut → "Publié" |
| 5 | agent-analytics | Fin semaine ou manuel | Rapport généré |

### Instructions d'orchestration

Quand tu reçois la commande `/pipeline` ou que `master-pipeline.sh` te lance :

```
1. Lance l'agent "agent-content" avec la tâche :
   "Lis la Notion DB ASPAR Social Media, génère tous les textes pour les
   entrées avec statut 'À rédiger', met à jour le statut → 'Texte prêt'"

2. Attends la confirmation de fin de agent-content.
   Si erreur → stoppe et notifie Slack.

3. Lance l'agent "agent-visual" avec la tâche :
   "Récupère les entrées Notion 'Texte prêt', génère 5 slides Canva
   (slide1=Majdi cover, slides2-5=design Pinterest) avec les couleurs
   #1B2A4A et #F47920, exporte multi-formats, met à jour statut → 'Visuels prêts'"

4. Attends la confirmation de fin de agent-visual.
   Si erreur → stoppe et notifie Slack.

5. Lance l'agent "agent-pdf" avec la tâche :
   "Récupère les entrées Notion 'Visuels prêts', assemble les slides en PDF
   Puppeteer aux formats LinkedIn 1080x1350 / IG 1080x1080 / Stories
   1080x1920 / Pinterest 1000x1500, met à jour statut → 'PDF prêt'"

6. Attends la confirmation de fin de agent-pdf.
   Si erreur → stoppe et notifie Slack.

7. Lance l'agent "agent-publish" avec la tâche :
   "Récupère les entrées Notion 'PDF prêt', publie via n8n MCP
   (https://notoria.app.n8n.cloud/mcp-server/http) → Buffer pour
   LinkedIn/IG/FB, Twin webhook pour TikTok/Pinterest, met à jour
   statut → 'Publié'"

8. Attends la confirmation de fin de agent-publish.
   Si erreur → notifie Slack (ne pas stopper le pipeline, logger uniquement).

9. (Optionnel — lancé séparément chaque lundi) Lance l'agent "agent-analytics" :
   "Collecte les stats de la semaine écoulée sur toutes les plateformes,
   met à jour Notion, crée le brouillon Gmail pour Majdi"
```

## Commandes disponibles

| Commande | Action |
|----------|--------|
| `/pipeline` | Lance le pipeline complet (étapes 1→4) |
| `/pipeline-analytics` | Lance uniquement l'agent analytics |
| `/pipeline-content` | Lance uniquement la génération de contenu |
| `/pipeline-visual` | Lance uniquement la génération visuelle |
| `/pipeline-pdf` | Lance uniquement l'assemblage PDF |
| `/pipeline-publish` | Lance uniquement la publication |
| `/pipeline-status` | Affiche le statut de toutes les entrées Notion |

## Structure des fichiers

```
aspar-group/
├── CLAUDE.md                    ← Ce fichier (orchestrateur)
├── master-pipeline.sh           ← Script de lancement automatique
├── .claude/
│   └── agents/
│       ├── agent-content.md     ← Agent 1: Génération contenus
│       ├── agent-visual.md      ← Agent 2: Génération visuels
│       ├── agent-pdf.md         ← Agent 3: Assemblage PDF
│       ├── agent-publish.md     ← Agent 4: Publication
│       └── agent-analytics.md  ← Agent 5: Analytics & rapports
├── scripts/
│   └── aspar-slides-to-pdf.js  ← Script Puppeteer PDF
└── output/
    └── [YYYYMMDD]-[sujet]/     ← Fichiers générés
        ├── linkedin/
        ├── instagram/
        ├── stories/
        └── pinterest/
```

## Variables d'environnement requises

Configurer dans `.env` ou l'environnement système :

```bash
# Notion
NOTION_API_KEY=secret_xxx

# Canva
CANVA_API_KEY=xxx

# n8n MCP
N8N_MCP_URL=https://notoria.app.n8n.cloud/mcp-server/http
N8N_API_KEY=xxx

# Buffer
BUFFER_ACCESS_TOKEN=xxx

# Gmail
GMAIL_CREDENTIALS=path/to/credentials.json

# Slack (pour notifications)
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/xxx
SLACK_CHANNEL=#social-media-pipeline
```

## Gestion des erreurs

- **Erreur agent-content** → Log Notion + Slack alert → Pipeline stoppé
- **Erreur agent-visual** → Log Notion + Slack alert → Pipeline stoppé
- **Erreur agent-pdf** → Log Notion + Slack alert → Pipeline stoppé
- **Erreur agent-publish** → Log Notion + Slack alert → Pipeline continue (analytics toujours lancé)
- **Erreur agent-analytics** → Log Notion + Slack alert → Erreur non bloquante

## Rapport de pipeline

À la fin de chaque pipeline complet, un résumé est posté dans Slack `#social-media-pipeline` :

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 ASPAR Pipeline — Résumé
━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Content : X textes générés
✅ Visual  : X×5 slides créés
✅ PDF     : X×4 formats exportés
✅ Publish : X posts publiés/planifiés
━━━━━━━━━━━━━━━━━━━━━━━━━━━
⏱ Durée totale : Xmin
📅 Prochain pipeline : [date]
```
