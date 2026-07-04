---
name: student-mentoring
description: "Onboard, profile, and train student users who want to learn DevOps, infrastructure, or AI deployment from scratch. Covers environment assessment, platform setup (WhatsApp/Slack gateway), goal profiling, and custom training plan generation."
version: 1.0.0
author: Hermes Agent
created_by: agent
tags: [onboarding, training, devops, students, mentoring, gateway, whatsapp, slack]
---

# Student Mentoring

A systematic process for transforming a beginner student into a DevOps-capable engineer. Used when the user is a student with little to no prior experience, wants structured learning, and needs Hermes configured on messaging platforms for continuous support.

## Onboarding Flow

### Phase 1 — Environment Health Check
Always start with `hermes doctor` to verify:
- Python env, config files, API keys
- Gateway service status
- Tool availability

If doctor flags issues, address them before proceeding.

### Phase 2 — Gateway Setup (WhatsApp & Slack)
Two common blockers:

**WhatsApp "Unauthorized user" fix:**
1. `hermes gateway status` — look for the user ID in the warning (e.g. `116054462304448@lid`)
2. Add to `~/.hermes/.env`:
   ```
   WHATSAPP_ALLOWED_USERS=<user_id>
   ```
   OR for open access:
   ```
   GATEWAY_ALLOW_ALL_USERS=true
   ```
3. `hermes gateway restart`
4. Verify: `hermes gateway status` or `tail -20 ~/.hermes/logs/gateway.log`

**Slack connection issues:**
- Bot token must start with `xoxb-` (not `xapp-` or user token)
- Enable Socket Mode in Slack App settings
- Required scopes: `chat:write`, `app_mentions:read`, `channels:history`
- Slack triggers `hermes slack manifest` to register slash commands

If the gateway is running but the platform shows as not connected, check logs:
```bash
tail -50 ~/.hermes/logs/gateway.log | grep -E 'whatsapp|slack|Unauthorized|connected|disconnected'
```

### Phase 3 — Model Provider Setup
If the user already uses a model provider (e.g. OpenCode Zen):

```bash
# Add API key to .env
echo 'OPENCODE_ZEN_API_KEY=***' >> ~/.hermes/.env

# Select via interactive picker
hermes model

# Or configure directly
hermes config set model.default <model-name>
hermes config set model.provider <provider-name>
hermes config set model.base_url <api-endpoint>
```

Common providers and their env vars (from hermes-agent SKILL.md):
| Provider | Env var | Provider ID |
|----------|---------|-------------|
| OpenCode Zen | `OPENCODE_ZEN_API_KEY` | `opencode-zen` |
| Anthropic | `ANTHROPIC_API_KEY` | `anthropic` |
| DeepSeek | `DEEPSEEK_API_KEY` | `deepseek` |
| Nous | (OAuth via `hermes auth`) | `nous` |

### Phase 4 — User Profiling (Get-to-Know-You)
Ask these categories of questions in rounds:

**Round 1 — Profile:**
- Role/major: what are you studying?
- Tech stack: languages and tools you use/have
- Career goal: what do you want to become in 3-5 years?
- Current level: honest self-assessment (beginner, intermediate)

**Round 2 — Environment & Preferences:**
- OS (Linux/Windows/Mac/WSL)
- Learning style: concise vs detailed, reading vs video
- Tools installed (Git, Docker, VS Code, Python, Node.js, etc.)
- First project idea or area of interest

**Round 3 — Commitment:**
- Hours available per week (holidays vs school period)
- Preferred role: tutee (follow lessons), co-builder (work together), or assistant (you fix things for me)
- How they want to communicate: CLI, WhatsApp, Slack

Save all answers to memory via `memory(action='add', target='user')` and `memory(action='add', target='memory')`.

### Phase 5 — Training Plan Generation
For a beginner targeting DevOps/IA deployment, use the 8-week foundations structure (see `references/devops-foundations-training.md`).

Adjust based on:
- Available hours per week — scale weekly content proportionally
- Upcoming coursework — align topics (e.g. Réseaux at school → reinforce with practical networking week)
- Learning style — if they prefer reading, provide detailed markdown explanations; if hands-on, emphasize exercises

### Phase 6 — Ongoing Engagement & Daily Motivation Automation

After the training plan is validated, the student may ask for daily motivation reminders on WhatsApp/Slack. Automate this with a Hermes cron job that delivers a short inspiring message each morning.

**Setup Steps:**

1. **Discover available targets** — always check first:
   ```bash
   hermes send --list
   ```
   This shows all configured channels (e.g., `slack:general`, `whatsapp:Prénom`).

2. **Create the cron job** — via `cronjob(action='create')`:
   - Name: e.g. `"Rappel motivation quotidien"`
   - Schedule: `"0 7 * * *"` (7:00 AM daily — adjust timezone offset if needed)
   - prompt: include the full user context (name, 5-year goal, current training week, learning preferences)
   - deliver: `"all"` (sends to all configured platforms automatically)

3. **Message composition rules** (the cron job prompt should encode these):
   - 3-4 sentences max, natural French, discreet emoji
   - (1) Rappel de l'objectif à 5 ans (startup DevOps/IA locale)
   - (2) Rappel de l'étape actuelle du plan de formation
   - (3) Un conseil ou une pensée marquante adaptée au thème de la semaine
   - (4) Formule d'encouragement
   - No long bullet lists, no artificial tone

4. **Delivery within the cron job:**
   - Send via `hermes send --to platform:target --subject "🌅 Bonjour Prénom"` with piped stdin for the message body
   - Repeat for each target (WhatsApp DM, Slack channel)
   - Check exit code after each send — a non-zero exit means delivery failure
   - Success returns `"sent"` on stdout

5. **Progress awareness** — the cron agent should:
   - Use `session_search` to determine the student's current training week
   - Default to Week 1 (Linux) if no progress data exists
   - Adapt the daily advice to the current week's topic

**Key commands for messaging from scripts/cron:**
```bash
# List available targets
hermes send --list

# Send to Slack channel
cat << 'BODY' | hermes send --to slack:general --subject "🌅 Bonjour Gédéon"
[message]
BODY

# Send to WhatsApp DM
cat << 'BODY' | hermes send --to whatsapp:Gédéon --subject "🌅 Bonjour Gédéon"
[message]
BODY
```

**Pitfalls:**
- Using wrong target format — always `hermes send --list` first to get exact syntax
- Passing multi-line message as positional arg instead of piping stdin — pipe it
- Sending the same message every day — vary the advice/thought per week's topic
- Not verifying exit code on `hermes send` — silent failures leave the student unreached
- UTC vs local time mismatch in cron schedule — `0 7 * * *` is 07:00 UTC, adjust if the student is in a different timezone

## User Preferences to Capture in Memory

```yaml
memory(target='user'):
  - Prénom/nom, école, filière, année
  - Objectif carrière et horizon
  - Niveau actuel et technologies connues

memory(target='memory'):
  - Plan de formation validé
  - État d'avancement (semaine en cours)
  - Préférences de style et de communication
```

## Déploiement 24/7 pour étudiants sans budget

Quand le PC de l'étudiant est éteint, Hermes ne répond plus sur WhatsApp/Slack.
Voir `references/deployment-options-students.md` pour un comparatif complet des
solutions gratuites ou peu coûteuses :

| Option | Coût | Idéal si... |
|--------|------|-------------|
| **Termux (Android)** | $0 | L'étudiant a un smartphone Android toujours allumé |
| **Oracle Cloud Free Tier** | $0 | L'étudiant a une CB et la persévérance pour obtenir une instance ARM |
| **GitHub Student Pack → Azure** | $0 | L'étudiant est éligible au pack et n'a pas peur du cloud |
| **Hetzner CX22** | ~3.79€/mois | L'étudiant peut payer ~2500 FCFA/mois |

**Pour un étudiant sans budget** : Termux est le chemin le plus simple — 
téléphone déjà allumé, installation one-liner, officiellement supporté.
⚠️ Attention : la compilation des packages Rust sur ARM prend 20-40 min
(voir la reference pour les détails et les temps d'attente).
Voir la reference pour les étapes détaillées, les commandes wake-lock,
et les limitations connues. Si l'étudiant s'interroge sur la durée de la
compilation, voir `references/pourquoi-compilation-lente-termux.md` pour
une explication pédagogique complète (compilation vs interprétation,
pourquoi les packages Rust, ordre de compilation).

## Pitfalls

- **Forgetting to restart the gateway** after changing `.env` — always `hermes gateway restart`
- **Overloading the plan**: a beginner with 4-5h/week cannot do 8 topics. Consolidate to fewer, deeper weeks.
- **Assuming tool knowledge**: always verify `which git`, `python --version`, `docker --version` before assigning exercises that use them.
- **Skipping the goal check**: a student who says "DevOps" may mean "CI/CD pipelines" or "Kubernetes admin" — probe for the actual target.
- **French-speaking users**: respond in French, use French technical references when available (commandes, messages, documentation).

## Verification

After setup is complete:
```bash
hermes doctor              # overall health
hermes gateway status       # platforms connected
grep "whatsapp" ~/.hermes/logs/gateway.log | tail -5  # WhatsApp linked
```

Send a test message from WhatsApp/Slack before declaring done.
