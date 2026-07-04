---
name: hermes-provider-config
description: "Add, configure, and manage LLM providers and MoA (Mixture of Agents) presets in Hermes: credential setup via hermes auth, provider env vars, MoA preset archetypes, and switching between presets."
author: agent
version: 1.2.0
tags: [hermes, providers, moa, model, configuration, opencode-go, routing]
---


# Hermes Provider & MoA Configuration

Add model providers and configure MoA (Mixture of Agents) presets in Hermes.

## Scope

This skill covers:
- Adding/removing providers via `hermes auth` and environment variables
- Provider-specific model ID prefixes and endpoints
- MoA preset design and management
- Switching providers and presets at runtime

It complements `hermes-agent` (general agent config) and `hermes-operations` (server-side ops) by focusing specifically on **provider credentialing and model routing**.

---

## Adding a Provider

### Via `hermes auth add` (preferred)

Most providers support `hermes auth add <provider_name>`:

```bash
hermes auth add opencode-go
hermes auth add anthropic
hermes auth add openai-codex
```

This stores credentials in Hermes' credential pool (rotation, exhaustion tracking).

### Via environment variable

Alternatively, set the env var in `~/.hermes/.env`:

| Provider    | Provider name in config | Env var                  | Model ID prefix        |
|-------------|-------------------------|--------------------------|------------------------|
| OpenCode Go | `opencode-go`           | `OPENCODE_GO_API_KEY`    | `opencode-go/`         |
| OpenCode Zen| `opencode-zen`          | `OPENCODE_ZEN_API_KEY`   | `opencode/`            |
| OpenRouter  | `openrouter`            | `OPENROUTER_API_KEY`     | (provider name)        |
| Anthropic   | `anthropic`             | `ANTHROPIC_API_KEY`      | `anthropic/`           |
| OpenAI      | `openai`                | `OPENAI_API_KEY`         | `openai/`              |
| Google      | `google`                | `GOOGLE_API_KEY`         | `google/`              |
| DeepSeek    | `deepseek`              | `DEEPSEEK_API_KEY`       | `deepseek/`            |

### Verify the provider is recognised

```bash
hermes model
# Shows available providers and their models
```

---

## Selecting a Model

```bash
/model opencode-go/deepseek-v4-flash
/model opencode-go/deepseek-v4-pro
/model openrouter/anthropic/claude-opus-4.8

# Set as default for the session
/model default --provider opencode-go
```

Set in config.yaml to persist:

```bash
hermes config set model.provider opencode-go
hermes config set model.default opencode-go/deepseek-v4-flash
```

---

## MoA (Mixture of Agents) Presets

### What MoA does

MoA runs reference models (advisors) in parallel, then a single aggregator model produces the final response. This gives better quality on complex tasks at the cost of latency (~1-2 extra seconds) and extra token consumption.

### When to use MoA

| Situation                  | Use               |
|----------------------------|--------------------|
| Simple factual query       | Single model       |
| Debugging / architecture   | MoA (default)      |
| Code generation            | MoA (equilibre)    |
| Complex technical analysis | MoA (performance)  |
| Anything you want 2nd opinion | MoA (double-ref) |

### Preset archetypes

4 standard archetypes that cover most needs:

```yaml
# Minimal — cheapest, fastest MoA. Good daily driver.
default:
  reference_models:
    - provider: opencode-go
      model: deepseek-v4-flash
  aggregator:
    provider: opencode-go
    model: deepseek-v4-pro

# Equilibre — Flash + Kimi K2.7 (optimisé code)
equilibre:
  reference_models:
    - provider: opencode-go
      model: deepseek-v4-flash
  aggregator:
    provider: opencode-go
    model: kimi-k2.7-code

# Performance — Flash + Qwen3.7 Max (le plus fort des Go)
performance:
  reference_models:
    - provider: opencode-go
      model: deepseek-v4-flash
  aggregator:
    provider: opencode-go
    model: qwen3.7-max

# Double-ref — 2 avis avant décision
double-ref:
  reference_models:
    - provider: opencode-go
      model: deepseek-v4-flash
    - provider: opencode-go
      model: qwen3.7-plus
  aggregator:
    provider: opencode-go
    model: deepseek-v4-pro

### Preset gratuit — free-ultra

Preset MoA 100% gratuit. **Attention : OpenCode Zen gratuit est trop lent pour du MoA** (~26s par appel, 3 appels = ~78s = timeout). Utiliser OpenRouter à la place.

Modèles OpenRouter gratuits les plus fiables — **Nemotron Nvidia** (les seuls rarement rate-limités) :

```yaml
free-ultra:
  reference_models:
    - provider: openrouter
      model: nvidia/nemotron-3-super-120b-a12b:free
    - provider: openrouter
      model: nvidia/nemotron-3-ultra-550b-a55b:free
  aggregator:
    provider: openrouter
    model: nvidia/nemotron-3-ultra-550b-a55b:free
  max_tokens: 4096
  enabled: true
```

Latence : ~2-3s total (contre ~78s avec Zen). Voir `references/moa-free-ultra-preset.md`.

#### Modèles gratuits — fiabilité OpenRouter

| Modèle | Statut | Latence |
|--------|--------|---------|
| `nvidia/nemotron-3-ultra-550b-a55b:free` | ✅ Fiable | ~0.8s |
| `nvidia/nemotron-3-super-120b-a12b:free` | ✅ Fiable | ~0.5s |
| `google/gemma-4-31b-it:free` | ❌ Rate-limité | N/A |
| `google/gemma-4-26b-a4b-it:free` | ❌ Rate-limité | N/A |
| `meta-llama/llama-3.3-70b-instruct:free` | ❌ Rate-limité | N/A |
| `qwen/qwen3-coder:free` | ❌ Rate-limité | N/A |
| `nousresearch/hermes-3-llama-3.1-405b:free` | ❌ Rate-limité | N/A |

### Switching between presets

```bash
/model default --provider moa       # use 'default' preset
/model default                      # shorthand (no conflict)
/model performance --provider moa
/model double-ref --provider moa
```

One-shot without changing current model:

```bash
/moa analyse cette architecture réseau
```

### Managing presets

```bash
hermes moa configure                    # update default interactively
hermes moa configure <name>             # create or update named preset
hermes moa list                          # list available presets
hermes moa delete <name>                 # remove a preset
```

For programmatic bulk edits (e.g. adding 4 presets at once), edit `~/.hermes/config.yaml` section `moa.presets` directly. Note that `patch` and `write_file` refuse to write to `config.yaml` — use `hermes config set` or a Python YAML script.

### Limitations

- Max ~2-3 reference models before quality plateau and latency becomes painful.
- Each reference model call costs tokens — MoA multiplies per-turn cost.
- Reference models run in parallel; total latency = slowest reference + aggregator.
- MoA is NOT recursive (aggregator cannot be another MoA preset).
- Credential failures on one reference model don't abort the turn — Hermes includes the failure message in the reference context.

---

## OpenCode Go & Zen — Specific Notes

### Endpoints

OpenCode AI a deux endpoints distincts pour ses deux offres :

| Offre | Endpoint | Modèles typiques |
|---|---|---|
| **Zen** (gratuit) | `https://opencode.ai/zen/v1` | `deepseek-v4-flash-free`, `mimo-v2.5-free` |
| **Go** (payant 5-10$/mois) | `https://opencode.ai/zen/go/v1` | `deepseek-v4-flash`, `deepseek-v4-pro`, `kimi-k2.7-code` |

**Latence Zen gratuit :** ~26s par appel. Cela rend le Zen inutilisable en MoA (3 appels séquentiels → timeout). Pour du MoA gratuit, préférer OpenRouter (Nemotron Nvidia, ~0.5-1s/appel).

**Piège :** le sous-domaine `api.opencode.ai` **n'existe pas** — ne jamais utiliser `https://api.opencode.ai/...`.

### Troubleshooting 401 / "Missing Authentication header" / empty stream / wrong endpoint
 
Symptômes :
- `hermes auth list` shows `auth failed (401)` for all keys of a provider.
- Runtime error points to `https://openrouter.ai/api/v1` even though the provider should use another host.
- `Provider returned an empty stream with no finish_reason` (flux vide) — souvent un endpoint inexistant.
- `hermes chat -q` works with curl but Hermes still says "no API key found".
 
First non-invasive check:
```bash
python3 -c "import yaml; yaml.safe_load(open('$HOME/.hermes/config.yaml'))"
# Test Zen
curl -sS -H 'Authorization: Bearer $OPENCODE_ZEN_API_KEY' \
  -H 'Content-Type: application/json' \
  -d '{"model":"deepseek-v4-flash-free","messages":[{"role":"user","content":"ping"}],"max_tokens":5}' \
  https://opencode.ai/zen/v1/chat/completions
# Test Go
curl -sS -H 'Authorization: Bearer $OPENCODE_GO_API_KEY' \
  -H 'Content-Type: application/json' \
  -d '{"model":"deepseek-v4-flash","messages":[{"role":"user","content":"ping"}],"max_tokens":5}' \
  https://opencode.ai/zen/go/v1/chat/completions
```
If curl succeeds but Hermes fails, the issue is routing/config, not credentials or account status.
 
Root causes, in order:
1. **Variable d'env `OPENCODE_ZEN_BASE_URL` / `OPENCODE_GO_BASE_URL` dans `.env`** — ces variables **écrasent** le `base_url` du provider dans `config.yaml`. Toujours vérifier les deux fichiers.
2. **Global `model.base_url` override** — a top-level `model.base_url` can send every provider to wrong endpoint. Remove it, or set provider-specific URLs under `providers:`.
3. **Malformed YAML** — invalid lines like `model?: false` anywhere in `config.yaml` can break parsing of later `providers:` and `moa:` sections.
4. **Duplicate provider in `providers:` section** — adding a built-in provider (like `opencode-zen` or `opencode-go`) under `providers:` creates a **second entry** in the model picker. The custom entry only shows the `default_model` (1 model), while the built-in shows the full model list (~40 models). The custom entry also uses custom auth resolution, not the built-in credential pool, causing 401 errors. Solution: remove the duplicated entry from `providers:` — the built-in provider handles everything.

**Hiérarchie de résolution du base_url** (ce qui gagne en cas de conflit) :
1. `.env` → `OPENCODE_*_BASE_URL` (priorité max)
2. `config.yaml` → `providers.<name>.base_url`
3. `config.yaml` → `model.base_url` (global, écrase tous les providers)
4. Code Hermes → valeur par défaut intégrée (dernier recours)
 
Fix sequence:
1. `grep -E '(OPENCODE_ZEN_BASE_URL|OPENCODE_GO_BASE_URL)' ~/.hermes/.env` — vérifier les overrides dans `.env`.
2. `grep -A5 '^model:' ~/.hermes/config.yaml | grep base_url` — vérifier le global override.
3. `grep -A8 '^providers:' ~/.hermes/config.yaml` — confirmer la section provider.
4. If broken:
   ```bash
   # Corriger l'override dans .env si nécessaire
   sed -i 's|api\\.opencode\\.ai/zen|opencode.ai/zen|' ~/.hermes/.env
   # Ou supprimer l'override du base_url global
   hermes config set model.base_url ""
   ```
5. If YAML is invalid, fix it manually or rewrite `config.yaml` from a known-good backup.
6. Relaunch Hermes; do NOT re-add credentials repeatedly unless the key itself changed.
 
Pitfall: `hermes auth reset <provider>` only clears exhaustion state; it does not fix routing or YAML issues. `hermes auth add` stacks credentials. Avoid duplicate 401 entries in the pool.

### Quick YAML validation before any config surgery

Always validate config.yaml is parseable before changing providers or MoA:

```bash
python3 -c "import yaml; yaml.safe_load(open('$HOME/.hermes/config.yaml'))"
```

If this fails, fix the YAML first. Common culprits: lines like `model?: false`, duplicate keys, indentation mismatches after manual edits.

### Credential housekeeping — list, prune, and avoid duplicates

After repeated `hermes auth add` calls, the credential pool can accumulate stale entries:

```bash
# List all credentials per provider
hermes auth list

# Remove a specific stale credential by index
hermes auth remove opencode-go 1   # removes entry #1

# Reset exhaustion state (does NOT fix routing or YAML issues)
hermes auth reset opencode-go
```

Rule: never re-add a credential to "fix" a 401 that is actually caused by routing or bad YAML. Verify with curl first (see above), then check config parsing, then check base_url routing.

### Security: keep api_key out of config.yaml

Hermes stores provider API keys in `.env`. If `hermes config set providers.<name>.api_key` was ever run, the key lands **in plain text** inside `config.yaml`. To remove it:

```bash
# 1. Save the key to .env first (if not already there)
echo 'OPENCODE_GO_API_KEY="sk-..."' >> ~/.hermes/.env

# 2. Blank the key in config.yaml
hermes config set providers.opencode-go.api_key ""

# 3. Verify the key still works (it reads from env now)
curl -sS -H "Authorization: Bearer $OPENCODE_GO_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"deepseek-v4-flash","messages":[{"role":"user","content":"ping"}],"max_tokens":5}' \
  https://opencode.ai/zen/go/v1/chat/completions

# 4. If the key was already committed to a git vault, scrub and rotate the key.
```

Vault gitignore: keep `.env`, `config.yaml`, `auth.json`, `state.db`, `*.key`, `*.pem`, `memories/`, `sessions/` out of version control at all times.

### Pricing structure (as of July 2026)

| Item       | Cost  |
|------------|-------|
| First month | $5   |
| Following  | $10/mo |
| Usage cap  | $60/mo (in token value) |
| Cap overrun| Falls back to Zen balance (opt-in "Use balance") |

### Model economics (est. requests per 5h)

| Model              | Req/5h  | Best for            |
|--------------------|---------|----------------------|
| DeepSeek V4 Flash  | 31 650  | Daily driver, cheap  |
| MiMo-V2.5          | 30 100  | Similar to Flash     |
| DeepSeek V4 Pro    | 3 450   | Stronger reasoning   |
| MiniMax M3         | 3 200   | General purpose      |
| Qwen3.7 Plus       | 4 300   | Good quality/price   |
| Kimi K2.7 Code     | 1 350   | Optimisé code        |
| GLM-5.2            | 880     | Technique            |

### Error: `Free usage exceeded` or `402 Insufficient Balance`

- **On Zen free tier**: Known bug affecting all free models (DeepSeek V4 Flash Free, MiMo-V2.5 Free, North Mini Code Free, Nemotron 3 Ultra Free, Big Pickle). Can be a transient limit or a billing sync bug. Retry later or subscribe to Go.
- **On Go**: Check your usage cap at https://opencode.ai/auth. Enable "Use balance" to fall back to Zen credits.
- **On OpenRouter with auxiliary tasks** (title generation, compression, etc.): an HTTP 402 with a massive token estimate (65536) is caused by `_build_call_kwargs` silently dropping the `max_tokens` parameter for OpenRouter endpoints. The model defaults to its maximum output, and OpenRouter estimates cost accordingly — even if the actual response is tiny. See `references/openrouter-auxiliary-max-tokens.md` for the root cause, fix, and re-application instructions.

---

## References

- `references/openrouter-auxiliary-max-tokens.md` — Root cause and fix for HTTP 402 on OpenRouter auxiliary calls when `max_tokens` is silently dropped by `_build_call_kwargs`, causing 65k token billing estimates. Includes the site-packages patch location and the caveat that it must be re-applied after `hermes update`.
- `references/hermes-audit-prompt.md` — read-only audit prompt for skills, sync/GitHub strategy, and Hermes config optimization.
- `references/moa-opencode-go-presets.md` — MoA preset archetypes for OpenCode Go models.
- `references/moa-free-ultra-preset.md` — MoA preset 100% gratuit (OpenCode Zen : Flash + Nemotron 3 Ultra).
- `references/opencode-zen-base-url-fix.md` — Correction du base_url OpenCode Zen : `opencode.ai` → `api.opencode.ai`. Cause, diagnostic, et procédure de correction.

## Templates

- `templates/friend-onboarding-prompt.md` — a comprehensive prompt a friend can paste into their fresh Hermes to get profiled and configured step by step.
