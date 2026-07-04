#!/bin/bash
# pull-hermes-config.sh — Tire les changements depuis GitHub vers le VPS
# Integre les modifications de hermes-config/ dans ~/.hermes/

VAULT="/root"
HERMES="/root/.hermes"
HERMES_CONFIG="/root/hermes-config"

echo "=== Pull depuis GitHub ==="
cd "$VAULT" || exit 1
git pull origin main 2>&1

echo ""
echo "=== Integration dans Hermes ==="
CHANGES=0

# SOUL.md
if [ -f "$HERMES_CONFIG/SOUL.md" ]; then
    if ! diff -q "$HERMES_CONFIG/SOUL.md" "$HERMES/SOUL.md" >/dev/null 2>&1; then
        cp "$HERMES_CONFIG/SOUL.md" "$HERMES/SOUL.md"
        echo "  SOUL.md : mis a jour"
        CHANGES=$((CHANGES+1))
    fi
fi

# Memories - NE PAS IMPORTER (chaque instance a son environnement)
# Les memoires sont specifiques a chaque machine pour eviter la confusion
echo "  memories : ignore (instance-specific)"

# Scripts
if [ -d "$HERMES_CONFIG/scripts" ]; then
    for script in "$HERMES_CONFIG/scripts/"*; do
        name=$(basename "$script")
        [ -f "$script" ] || continue
        # Ignorer sync-hermes-config.sh (c'est le script inverse)
        [[ "$name" == sync-hermes-config.sh ]] && continue
        dest="$HERMES/scripts/$name"
        if [ ! -f "$dest" ] || ! diff -q "$script" "$dest" >/dev/null 2>&1; then
            cp "$script" "$dest"
            chmod +x "$dest" 2>/dev/null
            echo "  scripts/$name : $( [ -f "$dest" ] && echo 'mis a jour' || echo 'nouveau' )"
            CHANGES=$((CHANGES+1))
        fi
    done
fi

# Skills (nouvelles seulement — ne supprime pas les existantes)
if [ -d "$HERMES_CONFIG/skills" ]; then
    for skill_dir in "$HERMES_CONFIG/skills/"*/; do
        [ -d "$skill_dir" ] || continue
        name=$(basename "$skill_dir")
        dest="$HERMES/skills/$name"
        if [ ! -d "$dest" ]; then
            mkdir -p "$dest"
            cp -r "$skill_dir"/* "$dest/"
            echo "  skills/$name : nouvelle skill importee"
            CHANGES=$((CHANGES+1))
        fi
    done
fi

if [ "$CHANGES" -eq 0 ]; then
    echo "  Aucun changement detecte."
else
    echo ""
    echo "✅ $CHANGES element(s) integre(s) dans Hermes (VPS)."
fi
