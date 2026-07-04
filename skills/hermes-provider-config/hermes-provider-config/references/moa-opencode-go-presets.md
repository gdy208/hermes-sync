# MoA Presets avec OpenCode Go — 4 archetypes

Ces presets ont été créés sur une instance Hermes connectée à OpenCode Go (abonnement $5 puis $10/mois).

## Prérequis

- `OPENCODE_GO_API_KEY` configurée (via `hermes auth add opencode-go` ou dans `.env`)
- Modèles Go disponibles : `opencode-go/deepseek-v4-flash`, `opencode-go/deepseek-v4-pro`, `opencode-go/kimi-k2.7-code`, `opencode-go/qwen3.7-max`, `opencode-go/qwen3.7-plus`

## Les 4 presets

### 1. default — Minimal (quotidien)
Réf : Flash (léger, 0.14$/M) → Aggr : Pro (plus fort, 1.74$/M)
~31 650 réf + 3 450 aggr req/5h
Bon pour : usage général, debug, explications

### 2. equilibre — Flash + Kimi K2.7 (code)
Réf : Flash → Aggr : Kimi K2.7 Code (optimisé code)
Bon pour : génération de code, scripts, révision

### 3. performance — Flash + Qwen3.7 Max (max)
Réf : Flash → Aggr : Qwen3.7 Max (2.50$/M, le + fort de Go)
Bon pour : sujets complexes, architecture, examens

### 4. double-ref — 2 avis + Pro
Réf : Flash + Qwen3.7 Plus (2 avis) → Aggr : Pro
Bon pour : tout sujet sensible où 2 opinions valent mieux qu'une

## Comment basculer

```bash
/model default --provider moa      # ou juste /model default
/model equilibre --provider moa
/model performance --provider moa
/model double-ref --provider moa
```

One-shot sans changer le modèle courant :
```bash
/moa analyse cette config réseau
```

## Section YAML complète

```yaml
moa:
  presets:
    default:
      reference_models:
        - provider: opencode-go
          model: deepseek-v4-flash
      aggregator:
        provider: opencode-go
        model: deepseek-v4-pro
      max_tokens: 4096
      enabled: true

    equilibre:
      reference_models:
        - provider: opencode-go
          model: deepseek-v4-flash
      aggregator:
        provider: opencode-go
        model: kimi-k2.7-code
      max_tokens: 4096
      enabled: true

    performance:
      reference_models:
        - provider: opencode-go
          model: deepseek-v4-flash
      aggregator:
        provider: opencode-go
        model: qwen3.7-max
      max_tokens: 4096
      enabled: true

    double-ref:
      reference_models:
        - provider: opencode-go
          model: deepseek-v4-flash
        - provider: opencode-go
          model: qwen3.7-plus
      aggregator:
        provider: opencode-go
        model: deepseek-v4-pro
      max_tokens: 4096
      enabled: true
```

## Limites connues

- Au-delà de 2-3 références, le gain en qualité plafonne.
- Plus de références = plus lent (attente du plus lent à chaque tour).
- Chaque référence est un appel facturé.
- MoA n'est pas récursif (pas de MoA dans MoA).
