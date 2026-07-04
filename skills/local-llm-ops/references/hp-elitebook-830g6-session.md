# Session de référence — Installation locale sur i5-8365U

Machine source de cette config : HP EliteBook 830 G6, Debian 13, Wayland.

## Hardware

- CPU: Intel i5-8365U (4C/8T, Whiskey Lake, AVX2+FMA)
- RAM: 14 GB (8.3 GB disponible après bureau)
- Stockage: 43 GB libre sur /home
- GPU: Intel UHD 620 (inutilisable pour inference)

## Modèles installés

| Modèle | Fichier | Taille disque | Port Hermes |
|--------|---------|--------------|-------------|
| Qwen3-8B Q4_K_M | `~/models/Qwen3-8B-Q4_K_M.gguf` | ~5.0 GB | 8080 → `custom:local-qwen` |
| Qwen2.5-Coder-7B Q4_K_M | `~/models/Qwen2.5-Coder-7B-Q4_K_M.gguf` | ~4.0 GB | 8081 → `custom:local-coder` |
| Llama-3.2-3B Q8_0 | `~/models/Llama-3.2-3B-Q8_0.gguf` | ~3.3 GB | 8082 → `custom:local-llama` |

## Sources HuggingFace

```
Qwen3-8B:    bartowski/Qwen_Qwen3-8B-GGUF → Qwen_Qwen3-8B-Q4_K_M.gguf
Coder 7B:    bartowski/Qwen2.5-Coder-7B-Instruct-GGUF → Qwen2.5-Coder-7B-Instruct-Q4_K_M.gguf
Llama3 3B:   hugging-quants/Llama-3.2-3B-Instruct-Q8_0-GGUF → llama-3.2-3b-instruct-q8_0.gguf
```

## Config Hermes

```yaml
custom_providers:
  - name: local-qwen
    base_url: http://localhost:8080/v1
  - name: local-coder
    base_url: http://localhost:8081/v1
  - name: local-llama
    base_url: http://localhost:8082/v1
```

Commande de configuration :
```bash
hermes config set custom_providers '[...]'
```

## Performances observées (mesures réelles, juillet 2026)

### Llama-3.2-3B Q8_0 (port 8082)
```
curl http://localhost:8082/v1/chat/completions -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"salut en 5 mots"}]}'
```
- Prompt: 3.8 tok/s (16 tokens, 4254 ms)
- Génération: 0.7 tok/s (8 tokens, 11476 ms — très lent pour Q8 à cause de la bande passante mémoire)
- Latence totale: ~16s pour une réponse de 8 tokens
- Remarque: Q8_0 sur 3B = 1.07 Go/1B paramètre, beaucoup de calcul par token

### Qwen3-8B Q4_K_M (port 8083)
```
curl http://localhost:8083/v1/chat/completions -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"dis bonjour en 2 mots"}]}'
```
- Prompt: 3.0 tok/s (7 tokens, 2315 ms)
- Génération: 1.46 tok/s (138 tokens, 94378 ms)
- Latence totale: ~96s pour 138 tokens (complet)
- Remarque: Q4_K_M sur 8B = 0.59 Go/1B paramètre, meilleur débit par Go de modèle

### Qwen2.5-Coder-7B Q4_K_M (port 8081)
Non testé dans cette session. Performance estimée similaire à Qwen3-8B.

### Conclusion
Sur cet i5-8365U (4C/8T Whiskey Lake, AVX2), les modèles Q4_K_M 7-8B offrent le meilleur rapport qualité/vitesse.
- Génération: 1-2 tok/s — utilisable pour des tâches non interactives (génération de code, documentation, tutorat)
- Pas assez rapide pour une conversation temps réel
- Le Llama 3.2 3B en Q8 n'est PAS plus rapide que le Qwen3-8B Q4_K_M pour la génération (0.7 vs 1.5 tok/s)
- Pour un usage interactif acceptable (>5 tok/s), viser des modèles <=3B en Q4_K_M
