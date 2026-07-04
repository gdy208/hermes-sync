#!/bin/bash
# =============================================================================
# hermes-sync.sh — Script de synchronisation unifié VPS ↔ OPTIMUS
# Placé dans ~/.hermes/scripts/ (pas dans le repo car exécuté par chaque instance)
#
# Usage :
#   hermes-sync              # exécution normale
#   hermes-sync --dry-run    # affiche ce qui serait fait sans rien modifier
#   hermes-sync --verbose    # détail complet
#
# Logique :
#   1. Pull du repo git@github.com:gdy208/hermes-sync.git
#   2. Intégration descendante (repo → ~/.hermes/)
#   3. Export montant (~/.hermes/ → repo) avec filtre d'identité
#   4. Push + tag hermes-sync-last
# =============================================================================

set -euo pipefail
shopt -s nullglob

# =====================================================================
# CONFIGURATION
# =====================================================================
VAULT_DIR="$HOME/obsidian-vault"
REPO_DIR="$VAULT_DIR/hermes-config"
HERMES_DIR="$HOME/.hermes"
REMOTE_URL="git@github.com:gdy208/hermes-sync.git"
TAG_NAME="hermes-sync-last"
LOCK_FILE="/tmp/hermes-sync.lock"

DRY_RUN=false
VERBOSE=false

# Patterns d'identité — détectés dynamiquement selon la machine
# VPS : IP IONOS, "IONOS", "cloudflared tunnel"
# OPTIMUS : hostname, IP locale, "OPTIMUS"
HOSTNAME=$(hostname -f 2>/dev/null || hostname)
LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "")

SENSITIVE_PATTERNS=(
    "212\\.132\\.75\\.49"  # IP VPS IONOS
    "IONOS"                 # Nom du provider VPS
    "cloudflared tunnel"    # Commande spécifique au VPS
    "pare-feu provider bloque tous les ports entrants"  # Mémoire VPS
    "$HOSTNAME"            # Nom de la machine actuelle
)

# Ajouter l'IP locale si détectée
if [ -n "$LOCAL_IP" ] && [ "$LOCAL_IP" != "127.0.0.1" ]; then
    SENSITIVE_PATTERNS+=("$LOCAL_IP")
fi

# =====================================================================
# ARGUMENTS
# =====================================================================
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --verbose) VERBOSE=true ;;
        *) echo "Argument inconnu : $arg"; exit 1 ;;
    esac
done

# =====================================================================
# FONCTIONS UTILITAIRES
# =====================================================================
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok()   { echo -e "${GREEN}[OK]${NC}   $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_err()  { echo -e "${RED}[ERR]${NC}  $1"; }
log_verbose() { $VERBOSE && echo -e "  ${BLUE}│${NC} $1"; }

# Vérifie si un fichier contient des patterns sensibles
is_sensitive() {
    local file="$1"
    for pattern in "${SENSITIVE_PATTERNS[@]}"; do
        if grep -qE "$pattern" "$file" 2>/dev/null; then
            return 0
        fi
    done
    return 1
}

# Copie atomique (cp vers tmp puis mv)
atomic_copy() {
    local src="$1" dst="$2" tmp="${2}.tmp.$$"
    if $DRY_RUN; then log_verbose "[DRY] cp $src → $dst"; return 0; fi
    if cp "$src" "$tmp" 2>/dev/null; then mv "$tmp" "$dst"; return 0
    else rm -f "$tmp"; return 1; fi
}

# Copie atomique de dossier
atomic_copy_dir() {
    local src="$1" dst="$2" tmp="${2}.tmp.$$"
    if $DRY_RUN; then log_verbose "[DRY] cp -r $src → $dst"; return 0; fi
    rm -rf "$tmp" 2>/dev/null || true
    if cp -r "$src" "$tmp" 2>/dev/null; then
        rm -rf "$dst" 2>/dev/null || true
        mv "$tmp" "$dst"; return 0
    else rm -rf "$tmp" 2>/dev/null || true; return 1; fi
}

# =====================================================================
# LOCKFILE
# =====================================================================
if [ -f "$LOCK_FILE" ]; then
    log_err "Sync déjà en cours (lockfile : $LOCK_FILE)"
    exit 1
fi
trap 'rm -f "$LOCK_FILE"' EXIT
touch "$LOCK_FILE"

# =====================================================================
# COMPTEURS
# =====================================================================
DOWN_NEW=0; DOWN_UPDATED=0; DOWN_DELETED=0
UP_EXPORTED=0; UP_SKIPPED=0

# =====================================================================
# PHASE 1 : PULL
# =====================================================================
log_info "PHASE 1 : Pull du repo..."

if [ ! -d "$REPO_DIR/.git" ]; then
    log_err "Repo non initialisé dans $REPO_DIR"
    exit 1
fi

cd "$REPO_DIR"

BEFORE=$(git rev-parse HEAD 2>/dev/null || echo "")

if $DRY_RUN; then
    log_info "[DRY-RUN] git pull --rebase origin main"
    AFTER="$BEFORE"
else
    git fetch origin --tags --force 2>/dev/null || true
    git pull --rebase origin main 2>&1 | grep -v "^$" || true
    AFTER=$(git rev-parse HEAD)
fi

# Récupérer le tag de dernière sync
LAST_TAG=$(git rev-parse "$TAG_NAME" 2>/dev/null || echo "$BEFORE")

if [ "$BEFORE" = "$AFTER" ] || [ -z "$BEFORE" ]; then
    log_ok "Repo à jour"
else
    COMMITS=$(git rev-list --count "$BEFORE".."$AFTER" 2>/dev/null || echo "0")
    log_ok "Pull : $COMMITS commit(s) récupéré(s)"
fi

# =====================================================================
# PHASE 2 : INTÉGRATION DESCENDANTE (repo → ~/.hermes/)
# =====================================================================
log_info "PHASE 2 : Intégration descendante (repo → ~/.hermes/)..."

# Calculer les fichiers changés depuis la dernière sync
if [ -n "$LAST_TAG" ] && [ "$LAST_TAG" != "$BEFORE" ]; then
    CHANGED=$(git diff --name-status "$LAST_TAG".."$AFTER" 2>/dev/null || true)
else
    # Première sync ou tag absent : tout considérer comme nouveau
    CHANGED=$(git diff --name-status 4b825dc642cb6eb9a060e54bf899d15363d7aa09.."$AFTER" 2>/dev/null || true)
fi

if [ -z "$CHANGED" ]; then
    log_ok "Aucun changement descendant"
else
    while IFS=$'\t' read -r status file; do
        [ -z "$file" ] && continue

        case "$status" in
            A|M)
                # Ajout ou modification
                if [[ "$file" == skills/* ]]; then
                    # Skill : copier le dossier entier si SKILL.md a changé
                    skill_name=$(echo "$file" | cut -d'/' -f2)
                    repo_skill_dir="$REPO_DIR/skills/$skill_name"
                    local_skill_dir="$HERMES_DIR/skills/$skill_name"

                    if [ ! -d "$local_skill_dir" ]; then
                        # Nouvelle skill
                        if atomic_copy_dir "$repo_skill_dir" "$local_skill_dir"; then
                            log_ok "Nouvelle skill : $skill_name"
                            DOWN_NEW=$((DOWN_NEW + 1))
                        fi
                    elif [ -f "$repo_skill_dir/SKILL.md" ] && [ -f "$local_skill_dir/SKILL.md" ]; then
                        # Skill existante : comparer MD5
                        repo_md5=$(md5sum "$repo_skill_dir/SKILL.md" | cut -d' ' -f1)
                        local_md5=$(md5sum "$local_skill_dir/SKILL.md" | cut -d' ' -f1)
                        if [ "$repo_md5" != "$local_md5" ]; then
                            if atomic_copy_dir "$repo_skill_dir" "$local_skill_dir"; then
                                log_ok "Skill mise à jour : $skill_name"
                                DOWN_UPDATED=$((DOWN_UPDATED + 1))
                            fi
                        fi
                    fi

                elif [[ "$file" == scripts/* ]]; then
                    # Script : copier le fichier
                    script_name=$(basename "$file")
                    repo_script="$REPO_DIR/scripts/$script_name"
                    local_script="$HERMES_DIR/scripts/$script_name"

                    if [ ! -f "$local_script" ]; then
                        if atomic_copy "$repo_script" "$local_script"; then
                            chmod +x "$local_script" 2>/dev/null || true
                            log_ok "Nouveau script : $script_name"
                            DOWN_NEW=$((DOWN_NEW + 1))
                        fi
                    elif [ -f "$repo_script" ]; then
                        repo_md5=$(md5sum "$repo_script" | cut -d' ' -f1)
                        local_md5=$(md5sum "$local_script" | cut -d' ' -f1)
                        if [ "$repo_md5" != "$local_md5" ]; then
                            if atomic_copy "$repo_script" "$local_script"; then
                                chmod +x "$local_script" 2>/dev/null || true
                                log_ok "Script mis à jour : $script_name"
                                DOWN_UPDATED=$((DOWN_UPDATED + 1))
                            fi
                        fi
                    fi
                fi
                ;;

            D)
                # Suppression
                if [[ "$file" == skills/*/SKILL.md ]]; then
                    skill_name=$(echo "$file" | cut -d'/' -f2)
                    local_skill_dir="$HERMES_DIR/skills/$skill_name"
                    if [ -d "$local_skill_dir" ]; then
                        if ! $DRY_RUN; then rm -rf "$local_skill_dir"; fi
                        log_warn "Skill supprimée : $skill_name"
                        DOWN_DELETED=$((DOWN_DELETED + 1))
                    fi
                elif [[ "$file" == scripts/* ]]; then
                    script_name=$(basename "$file")
                    local_script="$HERMES_DIR/scripts/$script_name"
                    if [ -f "$local_script" ]; then
                        if ! $DRY_RUN; then rm -f "$local_script"; fi
                        log_warn "Script supprimé : $script_name"
                        DOWN_DELETED=$((DOWN_DELETED + 1))
                    fi
                fi
                ;;
        esac
    done <<< "$CHANGED"
fi

# =====================================================================
# PHASE 3 : EXPORT MONTANT (~/.hermes/ → repo)
# =====================================================================
log_info "PHASE 3 : Export montant (~/.hermes/ → repo)..."

# 3a. Scripts
mkdir -p "$REPO_DIR/scripts"

for script in "$HERMES_DIR/scripts/"*.{sh,py}; do
    [ -f "$script" ] || continue
    name=$(basename "$script")

    # Exclure ce script lui-même et les scripts de sync
    [[ "$name" == hermes-sync* ]] && continue
    [[ "$name" == sync-* ]] && continue
    [[ "$name" == pull-* ]] && continue

    # Filtre d'identité
    if is_sensitive "$script"; then
        log_verbose "Script sensible ignoré : $name"
        UP_SKIPPED=$((UP_SKIPPED + 1))
        continue
    fi

    dest="$REPO_DIR/scripts/$name"
    if [ ! -f "$dest" ]; then
        if atomic_copy "$script" "$dest"; then
            chmod +x "$dest" 2>/dev/null || true
            log_ok "Script exporté : $name"
            UP_EXPORTED=$((UP_EXPORTED + 1))
        fi
    else
        src_md5=$(md5sum "$script" | cut -d' ' -f1)
        dest_md5=$(md5sum "$dest" | cut -d' ' -f1)
        if [ "$src_md5" != "$dest_md5" ]; then
            if atomic_copy "$script" "$dest"; then
                chmod +x "$dest" 2>/dev/null || true
                log_ok "Script mis à jour : $name"
                UP_EXPORTED=$((UP_EXPORTED + 1))
            fi
        fi
    fi
done

# 3b. Skills
mkdir -p "$REPO_DIR/skills"

for skill_dir in "$HERMES_DIR/skills/"*/; do
    [ -d "$skill_dir" ] || continue
    skill_name=$(basename "$skill_dir")

    # Exclure typeui-* et apple
    [[ "$skill_name" == typeui-* ]] && continue
    [[ "$skill_name" == "apple" ]] && continue

    # Filtre d'identité sur SKILL.md
    if [ -f "$skill_dir/SKILL.md" ] && is_sensitive "$skill_dir/SKILL.md"; then
        log_verbose "Skill sensible ignorée : $skill_name"
        UP_SKIPPED=$((UP_SKIPPED + 1))
        continue
    fi

    dest="$REPO_DIR/skills/$skill_name"
    if [ ! -d "$dest" ]; then
        if atomic_copy_dir "$skill_dir" "$dest"; then
            log_ok "Skill exportée : $skill_name"
            UP_EXPORTED=$((UP_EXPORTED + 1))
        fi
    elif [ -f "$skill_dir/SKILL.md" ] && [ -f "$dest/SKILL.md" ]; then
        src_md5=$(md5sum "$skill_dir/SKILL.md" | cut -d' ' -f1)
        dest_md5=$(md5sum "$dest/SKILL.md" | cut -d' ' -f1)
        if [ "$src_md5" != "$dest_md5" ]; then
            if atomic_copy_dir "$skill_dir" "$dest"; then
                log_ok "Skill mise à jour : $skill_name"
                UP_EXPORTED=$((UP_EXPORTED + 1))
            fi
        fi
    fi
done

# =====================================================================
# PHASE 4 : PUSH + TAG
# =====================================================================
log_info "PHASE 4 : Push vers GitHub..."

cd "$REPO_DIR"

# Vérifier s'il y a des changements à committer
HAS_CHANGES=false
if ! git diff --quiet 2>/dev/null; then HAS_CHANGES=true; fi
if ! git diff --cached --quiet 2>/dev/null; then HAS_CHANGES=true; fi
if git status --porcelain 2>/dev/null | grep -q .; then HAS_CHANGES=true; fi

if $HAS_CHANGES; then
    if $DRY_RUN; then
        log_info "[DRY-RUN] git add + commit + push"
    else
        git add skills/ scripts/ .gitignore 2>/dev/null || true
        if ! git diff --cached --quiet; then
            COMMIT_MSG="sync $(date +%Y-%m-%d_%H:%M) [+${DOWN_NEW} ~${DOWN_UPDATED} -${DOWN_DELETED} | ↑${UP_EXPORTED}]"
            git commit -m "$COMMIT_MSG" 2>&1
            git push origin main 2>&1 || { log_err "Push échoué"; exit 1; }
            git tag -f "$TAG_NAME" HEAD 2>/dev/null || true
            git push origin "$TAG_NAME" --force 2>/dev/null || true
            log_ok "Push réussi + tag $TAG_NAME mis à jour"
        else
            log_info "Aucun changement à committer"
        fi
    fi
else
    log_ok "Rien à exporter"
fi

# =====================================================================
# RAPPORT FINAL
# =====================================================================
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${GREEN}  SYNC TERMINÉE${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "  ${GREEN}↓ Descendant (repo → local)${NC}"
echo -e "    Nouveaux    : $DOWN_NEW"
echo -e "    Mis à jour  : $DOWN_UPDATED"
echo -e "    Supprimés   : $DOWN_DELETED"
echo -e ""
echo -e "  ${YELLOW}↑ Montant (local → repo)${NC}"
echo -e "    Exportés    : $UP_EXPORTED"
echo -e "    Filtrés     : $UP_SKIPPED (identité)"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"

if $DRY_RUN; then
    echo -e "${YELLOW}  MODE DRY-RUN — aucune modification réelle${NC}"
fi
