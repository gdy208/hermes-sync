---
name: hermes-local-models
description: "Set up, manage, and integrate local LLM inference (llama.cpp GGUF) with Hermes Agent on CPU-only machines. Covers building llama.cpp, downloading models, creating custom providers, fallback chains, and management scripts."
version: 1.0.0
author: Hermes Agent
license: MIT
tags:
  - local-models
  - llama.cpp
  - GGUF
  - fallback
  - cpu-inference
  - provider-configuration
---

# Hermes Local Models

## When to Use

- User wants to run local LLMs for offline use or backup
- Setting up a CPU-only machine (no GPU) for local inference
- Configuring Hermes to fall back to local models when cloud providers are unavailable
- Managing multiple GGUF models for different use cases (general, code, fast queries)

## Core Workflow

### 1. Build llama.cpp with OpenBLAS

```bash
git clone https://github.com/ggml-org/llama.cpp --depth 1
cd llama.cpp
cmake -B build -DLLAMA_BLAS=ON -DLLAMA_BLAS_VENDOR=OpenBLAS
cmake --build build -j4 --target llama-server
```

Verify with: `./build/bin/llama-server --version`

### 2. Download GGUF Models

Use `huggingface-cli` or direct curl downloads. Prefer `bartowski` quants for broad compatibility.

```bash
# List available quants via tree API
curl -s 'https://huggingface.co/api/models/bartowski/Qwen2.5-Coder-7B-Instruct-GGUF/tree/main' \
  | python3 -c "import json,sys; [print(s['path'],s['size']) for s in json.load(sys.stdin) if s['path'].endswith('.gguf')]"
```

### 3. Choose Models for CPU (per RAM budget)

| RAM available | Recommended setup |
|---------------|-------------------|
| 8-10 GB       | One 7-8B Q4_K_M (~4.5 GB) |
| 12-16 GB      | 8B Q4_K_M + 3B Q8_0 (~7.5 GB total) |
| 16-24 GB      | 8B Q4_K_M + 8B Q4_K_M + 3B Q8_0 |

### 4. Configure Hermes Custom Providers

```yaml
custom_providers:
  - name: local-qwen
    base_url: http://localhost:8083/v1
  - name: local-coder
    base_url: http://localhost:8081/v1
  - name: local-llama
    base_url: http://localhost:8082/v1
```

Set via `hermes config set custom_providers '[...]'`

### 5. Configurer la chaîne de fallback

```yaml
fallback_providers:
  - provider: custom
    model: qwen3
    base_url: http://localhost:8083/v1
  - provider: custom
    model: coder
    base_url: http://localhost:8081/v1
```

Vérifier : `hermes fallback list`

### 6. Créer un script de gestion

Créer `~/.hermes/scripts/local-ai` avec les sous-commandes :

- `local-ai start <model>` — démarre `llama-server` sur le port associé
- `local-ai stop` — tue tous les serveurs
- `local-ai status` — affiche ce qui tourne (port, PID, modèle)
- `local-ai list` — liste les modèles disponibles avec leur taille
- `local-ai switch <model>` — arrête le serveur actuel et en démarre un autre

### 7. Utiliser dans Hermes

Une fois le serveur lancé, basculer vers le modèle local :

```
/model local-qwen --provider custom:local-qwen
```

Ou laisser le fallback agir automatiquement si le provider principal échoue.

## Performance sur CPU (i5-8365U, 4 cœurs/8 threads)

| Modèle | Quant | RAM | Prompt | Génération |
|--------|-------|-----|--------|------------|
| Llama 3.2 3B | Q8_0 | ~3.2 Go | 3.8 tok/s | 0.7 tok/s |
| Qwen3-8B | Q4_K_M | ~4.7 Go | 3.0 tok/s | 1.5 tok/s |
| Qwen2.5-Coder-7B | Q4_K_M | ~4.4 Go | ~3 tok/s | ~1.5 tok/s |

Les valeurs sont indicatives. La première inférence inclut le temps de processing du prompt.

## Pièges

| Piège | Symptôme | Solution |
|-------|----------|----------|
| **Port 8080 occupé** | llama-server refuse de démarrer | Vérifier avec `ss -tlnp \| grep 8080`. docker-proxy ou autre service peut l'utiliser. Changer de port. |
| **Fallback ignoré** | `hermes fallback list` montre "No fallback providers" | Vérifier que `fallback_providers:` dans config.yaml est une liste YAML valide, pas une string. Corriger avec `sed -i` ou `hermes config set`. |
| **Modèle lent** | < 0.5 tok/s | Réduire ctx-size (2048), vérifier threads, utiliser Q4 au lieu de Q8 pour les modèles 7B+. |
| **Server crash au load** | "failed to load model" | GGUF corrompu → re-télécharger. RAM insuffisante → fermer les applis gourmandes. |

## Voir aussi

- Skill `llama-cpp` — téléchargement et sélection des GGUFs, paramètres avancés de llama.cpp
- Skill `systematic-debugging` — démarche pour diagnostiquer les problèmes d'inférence
- Doc Hermes : https://hermes-agent.nousresearch.com/docs/integrations/providers#named-custom-providers
