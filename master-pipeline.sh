#!/usr/bin/env bash
# =============================================================================
# ASPAR Franchise — Master Pipeline Social Media
# Lance le pipeline complet en séquence via Claude Code agents
# Usage: ./master-pipeline.sh [OPTIONS]
# Options:
#   --all          Pipeline complet (content → visual → pdf → publish) [défaut]
#   --analytics    Lance uniquement l'agent analytics (rapport hebdo)
#   --content      Lance uniquement la génération de contenu
#   --visual       Lance uniquement la génération visuelle
#   --pdf          Lance uniquement l'assemblage PDF
#   --publish      Lance uniquement la publication
#   --dry-run      Simule sans exécuter les agents
#   --verbose      Affiche les logs détaillés
# =============================================================================

set -euo pipefail

# ─── Configuration ────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
OUTPUT_DIR="${SCRIPT_DIR}/output"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="${LOG_DIR}/pipeline_${TIMESTAMP}.log"

# Couleurs ASPAR
NAVY='\033[38;2;27;42;74m'     # #1B2A4A
ORANGE='\033[38;2;244;121;32m' # #F47920
WHITE='\033[0;37m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
RESET='\033[0m'
BOLD='\033[1m'

# ─── Variables ────────────────────────────────────────────────────────────────

RUN_CONTENT=false
RUN_VISUAL=false
RUN_PDF=false
RUN_PUBLISH=false
RUN_ANALYTICS=false
DRY_RUN=false
VERBOSE=false
PIPELINE_START=$(date +%s)

# ─── Fonctions utilitaires ────────────────────────────────────────────────────

log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")

    case "$level" in
        INFO)    prefix="${GREEN}[INFO]${RESET}" ;;
        WARN)    prefix="${YELLOW}[WARN]${RESET}" ;;
        ERROR)   prefix="${RED}[ERROR]${RESET}" ;;
        AGENT)   prefix="${ORANGE}[AGENT]${RESET}" ;;
        SUCCESS) prefix="${GREEN}[SUCCESS]${RESET}" ;;
        *)       prefix="[LOG]" ;;
    esac

    echo -e "${timestamp} ${prefix} ${message}" | tee -a "${LOG_FILE}"
}

banner() {
    echo -e ""
    echo -e "${BOLD}${ORANGE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BOLD}${WHITE}  ASPAR Franchise — Social Media Pipeline${RESET}"
    echo -e "${BOLD}${ORANGE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${WHITE}  Date     : $(date '+%A %d %B %Y — %H:%M')${RESET}"
    echo -e "${WHITE}  Log      : ${LOG_FILE}${RESET}"
    echo -e "${ORANGE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e ""
}

check_env() {
    log INFO "Vérification des variables d'environnement..."

    local missing=()

    [[ -z "${NOTION_API_KEY:-}" ]] && missing+=("NOTION_API_KEY")
    [[ -z "${N8N_MCP_URL:-}" ]]    && missing+=("N8N_MCP_URL")
    [[ -z "${CANVA_API_KEY:-}" ]]  && missing+=("CANVA_API_KEY")

    if [[ ${#missing[@]} -gt 0 ]]; then
        log WARN "Variables manquantes (optionnelles en mode test) : ${missing[*]}"
    else
        log SUCCESS "Toutes les variables d'environnement sont configurées"
    fi
}

check_dependencies() {
    log INFO "Vérification des dépendances..."

    local deps=("node" "npm" "claude")
    local missing=()

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            missing+=("$dep")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log WARN "Dépendances manquantes : ${missing[*]}"
        log WARN "Certaines fonctionnalités peuvent ne pas être disponibles"
    else
        log SUCCESS "Toutes les dépendances sont disponibles"
    fi
}

run_agent() {
    local agent_name="$1"
    local agent_task="$2"
    local agent_file="${SCRIPT_DIR}/.claude/agents/${agent_name}.md"

    if [[ ! -f "$agent_file" ]]; then
        log ERROR "Agent introuvable : ${agent_file}"
        return 1
    fi

    log AGENT "Lancement de ${BOLD}${agent_name}${RESET}..."
    echo -e "${ORANGE}  ┌─ ${agent_name} ─────────────────────────────────────────${RESET}"

    if [[ "$DRY_RUN" == "true" ]]; then
        log INFO "  [DRY-RUN] Simulation de ${agent_name}"
        log INFO "  [DRY-RUN] Tâche : ${agent_task:0:80}..."
        sleep 1
        echo -e "${ORANGE}  └─ ${agent_name} : SIMULÉ ✓${RESET}"
        return 0
    fi

    local start_time
    start_time=$(date +%s)

    # Lancer Claude Code avec le prompt de l'agent
    local prompt="Tu es l'orchestrateur du pipeline ASPAR. Lance l'agent '${agent_name}' avec cette tâche exacte : ${agent_task}"

    if [[ "$VERBOSE" == "true" ]]; then
        claude --print "${prompt}" 2>&1 | tee -a "${LOG_FILE}"
    else
        claude --print "${prompt}" >> "${LOG_FILE}" 2>&1
    fi

    local exit_code=$?
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))

    if [[ $exit_code -eq 0 ]]; then
        echo -e "${GREEN}  └─ ${agent_name} : SUCCÈS ✓ (${duration}s)${RESET}"
        log SUCCESS "${agent_name} terminé en ${duration}s"
    else
        echo -e "${RED}  └─ ${agent_name} : ÉCHEC ✗ (code: ${exit_code})${RESET}"
        log ERROR "${agent_name} a échoué avec le code ${exit_code}"
        return $exit_code
    fi
}

notify_slack() {
    local message="$1"
    local webhook="${SLACK_WEBHOOK_URL:-}"

    if [[ -z "$webhook" ]]; then
        log WARN "SLACK_WEBHOOK_URL non configuré — notification ignorée"
        return 0
    fi

    curl -s -X POST "$webhook" \
        -H "Content-Type: application/json" \
        -d "{\"text\": \"${message}\"}" \
        >> "${LOG_FILE}" 2>&1 || log WARN "Notification Slack échouée"
}

pipeline_summary() {
    local end_time
    end_time=$(date +%s)
    local total_duration=$((end_time - PIPELINE_START))
    local minutes=$((total_duration / 60))
    local seconds=$((total_duration % 60))

    echo -e ""
    echo -e "${BOLD}${ORANGE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BOLD}${WHITE}  ✅ Pipeline ASPAR terminé${RESET}"
    echo -e "${ORANGE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    [[ "$RUN_CONTENT"   == "true" ]] && echo -e "  ${GREEN}✓${RESET} Content   : Textes générés"
    [[ "$RUN_VISUAL"    == "true" ]] && echo -e "  ${GREEN}✓${RESET} Visual    : 5 slides × contenu créés"
    [[ "$RUN_PDF"       == "true" ]] && echo -e "  ${GREEN}✓${RESET} PDF       : 4 formats exportés"
    [[ "$RUN_PUBLISH"   == "true" ]] && echo -e "  ${GREEN}✓${RESET} Publish   : Posts publiés/planifiés"
    [[ "$RUN_ANALYTICS" == "true" ]] && echo -e "  ${GREEN}✓${RESET} Analytics : Rapport généré"
    echo -e "${ORANGE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${WHITE}⏱  Durée totale : ${minutes}min ${seconds}s${RESET}"
    echo -e "  ${WHITE}📁 Log          : ${LOG_FILE}${RESET}"
    echo -e "${ORANGE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e ""
}

# ─── Parsing des arguments ────────────────────────────────────────────────────

parse_args() {
    if [[ $# -eq 0 ]]; then
        # Défaut : pipeline complet
        RUN_CONTENT=true
        RUN_VISUAL=true
        RUN_PDF=true
        RUN_PUBLISH=true
        return
    fi

    for arg in "$@"; do
        case "$arg" in
            --all)        RUN_CONTENT=true; RUN_VISUAL=true; RUN_PDF=true; RUN_PUBLISH=true ;;
            --analytics)  RUN_ANALYTICS=true ;;
            --content)    RUN_CONTENT=true ;;
            --visual)     RUN_VISUAL=true ;;
            --pdf)        RUN_PDF=true ;;
            --publish)    RUN_PUBLISH=true ;;
            --dry-run)    DRY_RUN=true ;;
            --verbose)    VERBOSE=true ;;
            --help|-h)
                echo "Usage: $0 [--all|--content|--visual|--pdf|--publish|--analytics] [--dry-run] [--verbose]"
                exit 0
                ;;
            *)
                log WARN "Argument inconnu : $arg"
                ;;
        esac
    done
}

# ─── Point d'entrée principal ─────────────────────────────────────────────────

main() {
    parse_args "$@"

    # Créer les répertoires nécessaires
    mkdir -p "${LOG_DIR}" "${OUTPUT_DIR}"

    # Charger .env si disponible
    if [[ -f "${SCRIPT_DIR}/.env" ]]; then
        set -a
        source "${SCRIPT_DIR}/.env"
        set +a
        log INFO ".env chargé"
    fi

    banner
    check_env
    check_dependencies

    if [[ "$DRY_RUN" == "true" ]]; then
        log WARN "Mode DRY-RUN activé — aucune action réelle ne sera effectuée"
    fi

    echo -e ""
    log INFO "Démarrage du pipeline ASPAR Social Media..."
    echo -e ""

    # ── ÉTAPE 1 : Content ─────────────────────────────────────────────────────
    if [[ "$RUN_CONTENT" == "true" ]]; then
        run_agent "agent-content" \
            "Lis la Notion DB ASPAR Social Media Calendar. Pour toutes les entrées avec statut 'À rédiger' ou 'Briefé', génère les textes complets pour LinkedIn, Instagram, Facebook et TikTok. Met à jour le statut Notion → 'Texte prêt'. Notifie dans Slack #social-media-pipeline." \
        || {
            log ERROR "Pipeline stoppé — Erreur agent-content"
            notify_slack "🔴 [ASPAR Pipeline] ERREUR agent-content — pipeline stoppé. Voir logs : ${LOG_FILE}"
            exit 1
        }
    fi

    # ── ÉTAPE 2 : Visual ──────────────────────────────────────────────────────
    if [[ "$RUN_VISUAL" == "true" ]]; then
        run_agent "agent-visual" \
            "Récupère toutes les entrées Notion avec statut 'Texte prêt'. Pour chacune, génère une série de 5 slides Canva : slide1=photo Majdi/business cover, slides2-5=design Pinterest épuré. Couleurs : fond #1B2A4A, accent #F47920. Exporte en formats LinkedIn/IG/Stories/Pinterest. Met à jour statut Notion → 'Visuels prêts'." \
        || {
            log ERROR "Pipeline stoppé — Erreur agent-visual"
            notify_slack "🔴 [ASPAR Pipeline] ERREUR agent-visual — pipeline stoppé. Voir logs : ${LOG_FILE}"
            exit 1
        }
    fi

    # ── ÉTAPE 3 : PDF ─────────────────────────────────────────────────────────
    if [[ "$RUN_PDF" == "true" ]]; then
        run_agent "agent-pdf" \
            "Récupère toutes les entrées Notion avec statut 'Visuels prêts'. Assemble les 5 slides en PDF Puppeteer pour chaque format : LinkedIn 1080x1350px, Instagram 1080x1080px, Stories 1080x1920px, Pinterest 1000x1500px. Sauvegarde dans /output/. Met à jour statut Notion → 'PDF prêt'." \
        || {
            log ERROR "Pipeline stoppé — Erreur agent-pdf"
            notify_slack "🔴 [ASPAR Pipeline] ERREUR agent-pdf — pipeline stoppé. Voir logs : ${LOG_FILE}"
            exit 1
        }
    fi

    # ── ÉTAPE 4 : Publish ─────────────────────────────────────────────────────
    if [[ "$RUN_PUBLISH" == "true" ]]; then
        run_agent "agent-publish" \
            "Récupère toutes les entrées Notion avec statut 'PDF prêt'. Publie via n8n MCP (https://notoria.app.n8n.cloud/mcp-server/http) : LinkedIn/Instagram/Facebook via Buffer, TikTok et Pinterest via Twin webhook. Met à jour statut Notion → 'Publié'. Notifie Slack avec les URLs de publication." \
        || {
            log WARN "Erreur agent-publish — pipeline continue (analytics toujours lancé)"
            notify_slack "🟡 [ASPAR Pipeline] ERREUR agent-publish — vérifier les publications manuellement."
        }
    fi

    # ── ÉTAPE 5 : Analytics (optionnelle) ─────────────────────────────────────
    if [[ "$RUN_ANALYTICS" == "true" ]]; then
        run_agent "agent-analytics" \
            "Collecte les statistiques de la semaine écoulée sur toutes les plateformes (LinkedIn, Instagram, Facebook, TikTok, Pinterest). Calcule les KPIs (impressions, engagement, reach, nouveaux abonnés). Met à jour chaque entrée Notion publiée. Crée la page rapport hebdo dans Notion. Génère le brouillon Gmail de rapport pour Majdi." \
        || {
            log WARN "Erreur agent-analytics — rapport hebdo non généré"
            notify_slack "🟡 [ASPAR Pipeline] ERREUR agent-analytics — rapport hebdo non généré."
        }
    fi

    # ── Résumé final ──────────────────────────────────────────────────────────
    pipeline_summary

    # Notification Slack de fin
    notify_slack "✅ [ASPAR Pipeline] Pipeline terminé avec succès — $(date '+%d/%m/%Y %H:%M')"

    log SUCCESS "Pipeline ASPAR terminé avec succès"
}

# ─── Lancement ────────────────────────────────────────────────────────────────

main "$@"
