# MoA Preset — free-ultra (100% gratuit, performance max)

**Créé le :** 2026-07-04
**Provider :** OpenCode Zen (built-in)
**Coût :** 0$ — modèles gratuits uniquement

## Architecture

| Rôle | Provider | Modèle | Description |
|---|---|---|---|
| **Référence 1** | `opencode-zen` | `deepseek-v4-flash-free` | Généraliste rapide, bon daily driver |
| **Référence 2** | `opencode-zen` | `nemotron-3-ultra-free` | Nvidia 550B, raisonnement profond |
| **Aggregator** | `opencode-zen` | `nemotron-3-ultra-free` | Synthèse par le plus fort des deux |

## Section YAML

```yaml
moa:
  presets:
    free-ultra:
      reference_models:
        - provider: opencode-zen
          model: deepseek-v4-flash-free
        - provider: opencode-zen
          model: nemotron-3-ultra-free
      aggregator:
        provider: opencode-zen
        model: nemotron-3-ultra-free
      max_tokens: 4096
      enabled: true
```

## Utilisation

```bash
# Basculer le modèle par défaut
/model free-ultra --provider moa

# Usage ponctuel (ne change pas le modèle courant)
/moa explique-moi cette architecture réseau
```

## Modèles gratuits disponibles sur OpenCode Zen

Liste des modèles tagués `-free` sur l'endpoint `https://opencode.ai/zen/v1` :

| Modèle | Description |
|---|---|
| `deepseek-v4-flash-free` | Généraliste, réactif |
| `nemotron-3-ultra-free` | Nvidia 550B, très costaud (1M ctx) |
| `mimo-v2.5-free` | Xiaomi, correct |
| `north-mini-code-free` | Spécialisé code (256K ctx) |

## Alternatives (autres presets MoA gratuits envisageables)

```yaml
# free-code — spécialisé code
free-code:
  reference_models:
    - provider: opencode-zen
      model: north-mini-code-free
  aggregator:
    provider: opencode-zen
    model: deepseek-v4-flash-free

# free-light — léger, rapide, 1 seule référence
free-light:
  reference_models:
    - provider: opencode-zen
      model: deepseek-v4-flash-free
  aggregator:
    provider: opencode-zen
    model: deepseek-v4-flash-free
```

## Notes

- Les modèles gratuits OpenCode Zen n'ont pas de limite de requêtes connue (pas de "Free usage exceeded" documenté pour l'instant).
- `big-pickle` est listé sur le endpoint Zen mais sans suffixe `-free` — statut non confirmé.
- Voir `references/moa-opencode-go-presets.md` pour les presets payants (OpenCode Go).
