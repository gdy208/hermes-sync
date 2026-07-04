#!/bin/bash
# local-ai — Gestionnaire de modèles IA locaux
# Usage: local-ai {start|stop|status|switch|list} [modele] [port]
#
# Skills parente : local-llm-ops
# Déploiement : mettre dans ~/.hermes/scripts/ + alias ou symlink
#
# Modèles disponibles:
#   qwen3   → Général + tuteur (port 8083 par défaut — 8080 souvent pris par docker)
#   coder   → Code sans internet (port 8081)
#   llama3  → Doc rapide / léger (port 8082)

CONFIG="$HOME/.local-ai"
mkdir -p "$CONFIG"

PIDFILE="$CONFIG/pid"
PORTFILE="$CONFIG/port"
MODELFILE="$CONFIG/model"

case "${1:-status}" in
  start)
    MODEL="${2:-qwen3}"
    PORT="${3:-}"
    
    case "$MODEL" in
      qwen3|qwen)
        GGUF="$HOME/models/Qwen3-8B-Q4_K_M.gguf"
        NAME="Qwen3-8B Q4_K_M"
        PORT="${PORT:-8083}"
        HERMES_PROVIDER="local-qwen"
        ;;
      coder)
        GGUF="$HOME/models/Qwen2.5-Coder-7B-Q4_K_M.gguf"
        NAME="Qwen2.5-Coder-7B Q4_K_M"
        PORT="${PORT:-8081}"
        HERMES_PROVIDER="local-coder"
        ;;
      llama3|llama)
        GGUF="$HOME/models/Llama-3.2-3B-Q8_0.gguf"
        NAME="Llama-3.2-3B Q8_0"
        PORT="${PORT:-8082}"
        HERMES_PROVIDER="local-llama"
        ;;
      *)
        echo "❌ Modèle inconnu : $MODEL"
        echo "   Utilise: qwen3, coder, ou llama3"
        exit 1
        ;;
    esac
    
    [ -f "$GGUF" ] || { echo "❌ Fichier introuvable : $GGUF"; ls -lh "$GGUF" 2>/dev/null; exit 1; }
    
    if ss -tlnp | grep -q ":$PORT "; then
      echo "❌ Port $PORT déjà occupé :"
      ss -tlnp | grep ":$PORT "
      exit 1
    fi
    
    echo "🚀 Lancement de $NAME sur le port $PORT..."
    echo "   API : http://localhost:$PORT/v1/chat/completions"
    echo "   Hermes : provider=$HERMES_PROVIDER"
    echo ""
    
    "$HOME/llama.cpp/build/bin/llama-server" \
      -m "$GGUF" \
      --host 127.0.0.1 --port "$PORT" \
      --ctx-size 8192 --threads 8 \
      --parallel 1 --cont-batching
    ;;
    
  stop)
    PORT="${2:-}"
    if [ -z "$PORT" ]; then
      pkill -f "llama.cpp/build/bin/llama-server" 2>/dev/null && echo "✅ Serveurs arrêtés" || echo "⚠️  Aucun serveur en cours"
    else
      fuser -k "$PORT/tcp" 2>/dev/null && echo "✅ Serveur sur le port $PORT arrêté" || echo "⚠️  Rien sur le port $PORT"
    fi
    ;;
    
  status)
    echo "=== Statut des modèles locaux ==="
    for port in 8081 8082 8083; do
      if ss -tlnp | grep -q ":$port "; then
        PID=$(ss -tlnp | grep ":$port " | grep -o 'pid=[0-9]*' | cut -d= -f2)
        CMDLINE=$(ps -p "$PID" -o args= 2>/dev/null | grep -oP '(?<=-m )[^ ]+' | head -1)
        NAME="inconnu"
        case "$CMDLINE" in *Qwen3-8B*) NAME="Qwen3-8B (qwen3)" ;; *Coder-7B*) NAME="Qwen2.5-Coder-7B (coder)" ;; *Llama-3.2-3B*) NAME="Llama-3.2-3B (llama3)" ;; esac
        echo "  ✅ Port $port — $NAME (PID $PID)"
      else
        echo "  ⬜ Port $port — libre"
      fi
    done
    echo ""
    echo "=== Espace disque ==="
    ls ~/models/*.gguf 2>/dev/null | wc -l | xargs echo "Modèles installés :"
    du -sh ~/models/ 2>/dev/null
    df -h /home | tail -1
    ;;
    
  switch)
    MODEL="${2:-}"
    [ -z "$MODEL" ] && { echo "Usage: $0 switch <qwen3|coder|llama3>"; exit 1; }
    pkill -f "llama.cpp/build/bin/llama-server" 2>/dev/null
    sleep 1
    exec "$0" start "$MODEL"
    ;;
    
  list)
    echo "=== Modèles disponibles ==="
    for f in "$HOME/models/"*.gguf; do
      [ -f "$f" ] || continue
      BASENAME=$(basename "$f")
      SIZE=$(du -h "$f" | cut -f1)
      case "$BASENAME" in
        *Qwen3-8B*) DESC="Général + Tuteur → local-qwen" ;;
        *Coder-7B*) DESC="Code → local-coder" ;;
        *Llama-3.2-3B*) DESC="Doc rapide → local-llama" ;;
        *) DESC="Non reconnu" ;;
      esac
      printf "  %-45s %s [%s]\n" "$BASENAME" "$DESC" "$SIZE"
    done
    ;;
    
  *)
    echo "Usage: local-ai {start|stop|status|switch|list} [modele] [port]"
    echo "Modèles: qwen3 (général), coder (code), llama3 (doc rapide)"
    ;;
esac
