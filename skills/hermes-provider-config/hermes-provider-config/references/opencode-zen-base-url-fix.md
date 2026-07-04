# OpenCode Zen — base_url correction

**Dernière mise à jour :** 2026-07-04
**Contexte :** Le provider `opencode-zen` retourne un flux vide (`Provider returned an empty stream with no finish_reason`) ou "Not Found".

## Cause racine

Le endpoint `https://api.opencode.ai/zen/v1` **n'existe pas**. OpenCode AI a deux vrais endpoints :

| Endpoint | Usage | Modèles |
|---|---|---|
| `https://opencode.ai/zen/v1` | ✅ **Zen (gratuit)** | `deepseek-v4-flash-free`, `mimo-v2.5-free`, etc. |
| `https://opencode.ai/zen/go/v1` | ✅ **Go (payant 5-10$/mois)** | `deepseek-v4-flash`, `deepseek-v4-pro`, `kimi-k2.7-code`, etc. |

Le faux endpoint `api.opencode.ai` (avec sous-domaine `api.`) n'est pas routé vers l'API OpenAI-compatible — retourne "Not Found" sur `/v1/models`.

## Vérification rapide

```bash
# Test direct de l'API Zen (gratuit)
curl -s https://opencode.ai/zen/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENCODE_ZEN_API_KEY" \
  -d '{"model":"deepseek-v4-flash-free","messages":[{"role":"user","content":"ping"}],"max_tokens":5}'
# Doit retourner HTTP 200 + JSON valide
```

## Diagnostic pas à pas

Si l'appel API échoue, trois niveaux de configuration peuvent être en cause :

### 1. `model.base_url` global dans `config.yaml`

Un `base_url` sous la section `model:` (pas sous `providers:`) écrase **tous les providers**. Vérifier :

```bash
grep -A5 '^model:' ~/.hermes/config.yaml | grep base_url
```

Si une ligne `base_url:` apparaît ici, la supprimer :
```bash
hermes config set model.base_url ""
```

### 2. Variable d'environnement `OPENCODE_ZEN_BASE_URL` dans `.env`

Le `.env` peut contenir une variable qui **écrase** le `base_url` du provider dans `config.yaml` :

```bash
grep OPENCODE_ZEN_BASE_URL ~/.hermes/.env
```

Si elle pointe vers `api.opencode.ai`, la corriger :
```bash
sed -i 's|api\\.opencode\\.ai/zen|opencode.ai/zen|' ~/.hermes/.env
```

### 3. Provider dans `config.yaml`

Vérifier la section provider :
```bash
grep -A3 'opencode-zen:' ~/.hermes/config.yaml
```

Doit ressembler à :
```yaml
opencode-zen:
  base_url: https://opencode.ai/zen/v1
  default_model: deepseek-v4-flash-free
```

Corriger si nécessaire :
```bash
hermes config set providers.opencode-zen.base_url https://opencode.ai/zen/v1
```

## Hiérarchie de résolution (ordre de précédence)

Comprendre ce qui gagne quand plusieurs configurations coexistent :

1. **Variable d'env** `OPENCODE_ZEN_BASE_URL` dans `.env` → **priorité max**
2. **Section provider** `providers.opencode-zen.base_url` dans `config.yaml`
3. **Section globale** `model.base_url` dans `config.yaml` → écrase tous les providers si présent
4. **Valeur par défaut codée en dur** dans le code Hermes

**Piège classique** : le `.env` contient `OPENCODE_ZEN_BASE_URL=https://api.opencode.ai/zen/v1` qui écrase silencieusement toute modification dans `config.yaml`. Toujours vérifier les deux fichiers.

## Modèles disponibles (Zen gratuit)

Liste non exhaustive des modèles gratuits sur `opencode.ai/zen/v1` :
- `deepseek-v4-flash-free`
- `mimo-v2.5-free`
- `nemotron-3-ultra-free`
- `north-mini-code-free`
- `big-pickle`

## Modèles disponibles (Go payant)

Liste non exhaustive des modèles Go sur `opencode.ai/zen/go/v1` :
- `deepseek-v4-flash`, `deepseek-v4-pro`
- `minimax-m3`, `minimax-m2.7`, `minimax-m2.5`
- `kimi-k2.7-code`, `kimi-k2.6`, `kimi-k2.5`
- `glm-5.2`, `glm-5.1`, `glm-5`
- `qwen3.7-max`, `qwen3.7-plus`, `qwen3.6-plus`, `qwen3.5-plus`
- `mimo-v2-pro`, `mimo-v2-omni`, `mimo-v2.5-pro`, `mimo-v2.5`
- `hy3-preview`
