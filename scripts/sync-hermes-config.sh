#!/bin/bash
# Synchronise la config Hermes (non sensible) vers le vault git

VAULT_HERMES="/root/obsidian-vault/hermes-config"

# SOUL.md (safe - partageable)
cp /root/.hermes/SOUL.md "$VAULT_HERMES/SOUL.md"

# Memories - NE PAS SYNC (chaque instance a son environnement)
# USER.md est partageable, MEMORY.md contient des infos VPS-specifiques
# On ne les exporte PAS pour eviter la confusion sur l'instance locale
# (Le USER.md est deja identique via le profil utilisateur)

# Scripts
mkdir -p "$VAULT_HERMES/scripts"
cp /root/.hermes/scripts/*.py "$VAULT_HERMES/scripts/" 2>/dev/null
cp /root/.hermes/scripts/*.sh "$VAULT_HERMES/scripts/" 2>/dev/null

# Skills custom (hors builtins TypeUI et skills preinstalles)
mkdir -p "$VAULT_HERMES/skills"
for skill in /root/.hermes/skills/*/; do
    name=$(basename "$skill")
    # Ignorer les gros packs TypeUI
    [[ "$name" == typeui-* ]] && continue
    # Ignorer les skills preinstalles volumineux
    [[ "$name" == "apple" ]] && continue
    size=$(du -s "$skill" 2>/dev/null | cut -f1)
    if [ "$size" -gt 500 ]; then
        echo "  skip $name (${size}KB)"
        continue
    fi
    cp -r "$skill" "$VAULT_HERMES/skills/"
done

# Profils (uniquement les infos pertinentes, pas les tokens)
if [ -f /root/.hermes/profiles/amie-maths/SOUL.md ]; then
    mkdir -p "$VAULT_HERMES/profiles/amie-maths"
    cp /root/.hermes/profiles/amie-maths/SOUL.md "$VAULT_HERMES/profiles/amie-maths/"
fi

echo "Config synced to vault."
