#!/bin/bash
# Sync Obsidian vault from GitHub — run daily via cron
# Uses git stash if local changes conflict with pull

VAULT_DIR="$HOME/obsidian"
cd "$VAULT_DIR" || { echo "ERREUR : dossier $VAULT_DIR introuvable"; exit 1; }

# Vérifier si on est bien dans un repo git
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "ERREUR : pas un dépôt git"
    exit 1
fi

echo "=== Sync Obsidian vault ==="
echo "Date : $(date '+%Y-%m-%d %H:%M:%S')"
echo "Repo : $(git remote get-url origin)"
echo ""

# Récupérer les infos avant pull
BEFORE=$(git rev-parse HEAD)
BEFORE_DATE=$(git log -1 --format=%cd --date=short)

# Tentative de pull avec stash si conflit
git stash push -m "auto-stash before pull $(date +%Y-%m-%d_%H%M)" 2>/dev/null

PULL_OUTPUT=$(git pull --ff-only 2>&1)
PULL_EXIT=$?

# Restaurer le stash (même si le pull a échoué, on restaure)
git stash pop 2>/dev/null

if [ $PULL_EXIT -ne 0 ]; then
    echo "ÉCHEC du pull :"
    echo "$PULL_OUTPUT"
    exit 1
fi

AFTER=$(git rev-parse HEAD)

if [ "$BEFORE" = "$AFTER" ]; then
    echo "✓ Déjà à jour — aucun changement."
else
    echo "✓ Mise à jour effectuée :"
    echo "  Avant : $BEFORE_DATE ($BEFORE)"
    echo "  Après : $(git log -1 --format=%cd --date=short) ($AFTER)"
    echo ""
    echo "Modifications :"
    git log --oneline "$BEFORE..$AFTER" --format="  • %s (%ar)"
fi
