---
name: cron-agent-briefing
description: "Use when setting up a cron-scheduled agent-driven briefing, research digest, or monitoring report. Covers: self-contained prompt design, structured output format with web research, per-platform delivery via UUID/chat_id, attach_to_session for reply capability, enabled_toolsets scoping, and conflict resolution when replacing existing jobs."
version: 1.0.0
author: Gédéon
created_by: agent
---

# Cron Agent Briefing — Automated Research & Report Scheduling

A pattern for creating Hermes cron jobs that produce **agent-driven briefings** — where an LLM agent performs web research on schedule and composes a structured report delivered to a messaging platform.

This is distinct from the no-agent watchdog pattern (script-only cron) and from static RSS monitoring (blogwatcher). Here, the agent does the research, synthesis, and formatting — the same work a human researcher would do.

## When to Use

- User wants a daily/weekly **briefing** on a class of topics (tech news, AI models, provider updates, competitor watch, market trends)
- User needs a **digest** summarizing recent developments across multiple sources
- User wants **alerting** when specific conditions are met (new model release, price drop, feature update)
- User wants the result delivered to a **specific messaging platform** (Signal, WhatsApp, Telegram, etc.) at a fixed time
- The output should be **replyable** — the user can ask follow-ups about the briefing content

**Do NOT use for:**
- Service monitoring / health checks → use `hermes-operations` watchdog pattern with `no_agent=True`
- Static RSS feed reading → use `blogwatcher` skill
- One-off research → just call `web_search` directly
- Tasks needing no synthesis or formatting → a script + `no_agent=True` is cheaper

## Anatomy of a Briefing Cron Job

A production briefing cron job has these components:

| Component | Purpose |
|-----------|---------|
| **Self-contained prompt** | No conversation history — the prompt must be complete, including identity, instructions, and output format |
| **`enabled_toolsets: ["web"]`** | Scopes the agent's tools to only web search — no terminal, file, or other tools needed |
| **`attach_to_session: true`** | Enables reply capability on the destination platform (user can respond to the briefing) |
| **Per-platform delivery** | Uses platform-specific chat ID or UUID (not just the platform name) |
| **Structured output format** | Defines the briefing structure inline so the agent produces consistent results |
| **`name`** | Descriptive name for management (`hermes cron list`) |

## Step-by-Step Workflow

### Step 1: Clarify Requirements

Ask the user:
- **Time**: What hour? Morning (7-9h) is typical for daily briefings
- **Delivery platform**: Which messaging platform? (Signal, WhatsApp, Telegram, Discord, etc.)
- **Topics**: What domains to cover? Be specific — list 3-5 categories
- **Language**: French or English?
- **Format**: Concise (bullets), detailed, or mixed?
- **Reply capability**: Does the user want to reply to the briefing for follow-ups?

### Step 2: Discover the Target Chat ID

For per-platform delivery, you need the platform-specific identifier, NOT just the platform name.

**Signal:**
```bash
# Read the sessions routing index to find the user's UUID
# The format is signal:<uuid> (e.g., signal:5db7d212-a539-405c-88f3-07e4538642b4)
```
- Found under `~/.hermes/sessions/sessions.json` as `origin.chat_id`
- Use UUID, NOT phone number — signal-cli cannot send to its own phone number
- The UUID appears in gateway log lines: `chat=<uuid>`

**WhatsApp:** `whatsapp:<phone_number>` (e.g., `whatsapp:22556341127`)
**Telegram:** `telegram:<chat_id>` (numerical ID)
**Discord:** `discord:<channel_id>:<thread_id>`

### Pattern: Adding Reddit as a Secondary Source

For briefings where community discussion is valuable (tech news, tools, models), integrate Reddit as a **bonus section**:

**How to reference subreddits in the prompt:**
- Use `site:reddit.com/r/SubredditName` in web_search calls
- Organize subreddits by category (one per section) + a dedicated bonus section
- Include both official (r/hermesagent, r/anthropic) and grassroots (r/LocalLLaMA, r/AIAgents) communities

**Subreddit family expansion pattern:** When the user says "ajoute aussi r/X et consorts", infer related subreddits:
- r/anthropic → r/ClaudeAI, r/OpenAI (ecosystem)
- r/hermesagent → r/opencodecli, r/AIAgents (agent tooling)
- r/MachineLearning → r/LocalLLaMA, r/artificial (general AI)

**Template for Reddit research instructions:**
```markdown
6. **Reddit** (bonus) — en complément des sections ci-dessus, fais un tour sur :
   - r/SubA : raison
   - r/SubB : raison
   - r/SubC : raison
```

**Best practices:**
- Integrate Reddit into each category section (not just a dump list) — e.g., "Inclus les discussions Reddit (r/SubA, r/SubB)" under Category 1
- Keep the bonus 👾 section at the bottom for the 1-2 best finds
- Reddit is best for: user sentiment, real-world experience with tools, early announcements, workarounds
- Avoid Reddit for: official release notes, pricing changes, API docs (use primary sources)

### Step 3: Design the Self-Contained Prompt

Key rules for cron prompts (they run with zero conversation history):

1. **Start with identity**: Who the agent is and who it works for
2. **Include explicit search instructions**: Tell the agent to search even if it thinks it already knows — stale internal knowledge is the #1 failure mode
3. **Use "even if you think you know" language**: Override the model's tendency to recall rather than search
4. **Define categories clearly**: Each category should be a named heading with specific search targets
5. **Structure the output format**: Give a template with emoji headers, placeholders, and length constraints
6. **Handle "nothing new" gracefully**: Tell the agent what to output when a category has no news ("Rien de neuf")
7. **End with a 'conseil du jour' / action item**: Makes the briefing useful beyond information

**Template structure:**

```markdown
Tu es un assistant de veille technologique spécialisé en [domaine]. Tu bosses pour [nom], un [rôle].

Produis un briefing [période] en [langue], frais et actionnable. Effectue des recherches web (web_search) pour chaque section ci-dessous, en ciblant les dernières 24-48h.

## Recherches à effectuer

1. **[Catégorie 1]** — cherche [cibles précises]. Inclus les discussions Reddit (r/SubA, r/SubB).
2. **[Catégorie 2]** — cherche [cibles précises].
3. **[Catégorie 3]** — cherche [cibles précises].

6. **Reddit** (bonus) — tour sur r/SubA, r/SubB, r/SubC.

## Format du briefing

```
☕ **Titre — {date}**

🧠 **Catégorie 1**
• Point concis (1-2 phrases)

📦 **Catégorie 2**
• Point concis

👾 **Reddit**
• 1-2 meilleures discussions repérées

💡 **Conseil du jour** : recommendation actionnable
```

## Règles
- Reste concis : 2-3 phrases max par sous-point
- Si une section n'a rien de nouveau : écris 'Rien de neuf'
- Ne répète PAS les sujets déjà couverts la veille
- Termine TOUJOURS par le 💡 Conseil du jour
- Langue : [langue] uniquement
- Pour Reddit, utilise `site:reddit.com/r/...` dans tes web_search
```

### Step 4: Set Schedule and Delivery

```python
cronjob(action="create",
    name="nom-du-job",
    schedule="0 7 * * *",           # every day at 7h
    deliver="signal:5db7d212-...",  # platform:chat_id
    enabled_toolsets=["web"],        # only web search tools
    attach_to_session=True,          # enable reply capability
    prompt="...")                    # self-contained prompt from step 3
```

**Schedule formats:**
- Daily: `"0 7 * * *"` (at 07:00 every day)
- Weekdays: `"0 7 * * 1-5"` (Mon-Fri at 07:00)
- Weekly: `"0 9 * * 1"` (Monday at 09:00)
- Duration: `"24h"` or `"every 12h"`

### Step 5: Handle Conflicts

Before creating, check for existing cron jobs that overlap:

```bash
hermes cron list
```

If an old job covers the same topic at a different time/platform:
- Ask the user: "Keep both, pause the old one, or delete?"
- Delete with `cronjob(action="remove", job_id="...")`
- The old job's script files can be cleaned up if no longer referenced

### Step 6: Verify Creation

After creation, confirm:
- `next_run_at` is set and makes sense (should be next occurrence of the schedule)
- Job appears in `hermes cron list`
- Job state is `"scheduled"` (not `"paused"`)
- `last_run_at` is `null` (not yet run — expected)
- No `last_delivery_error` on first creation

## Prompt Design Pitfalls

1. **Stale knowledge trap**: The agent will often skip searching and use its training data. Always add "even if you think you know, search anyway" instructions.
2. **Over-length prompts**: Cron prompts that are too long waste tokens every run. Keep the identity + instructions under 2000 chars.
3. **Missing "nothing new" fallback**: Without explicit handling, the agent fabricates news when there's nothing to report or hallucinates sources.
4. **No date in output**: Without a `{date}` placeholder, briefings look identical every day.
5. **Vague categories**: "AI news" is too broad. "New low-cost AI models (DeepSeek, Qwen, Mistral, Gemma)" gives the agent concrete search targets.
6. **Reddit as primary source for factual info**: Reddit is great for sentiment and early leaks, NOT for official pricing, API docs, or release notes. Always pair Reddit with official sources.
7. **Subreddit fragmentation**: Adding too many subreddits without organization overwhelms the agent. Group by category and prioritize 8-12 total.

## Common Pitfalls

1. **Forgetting `enabled_toolsets: ["web"]`** — the agent gets all default tools, wasting tokens on terminal/file ops it doesn't need for a briefing.
2. **Using phone number for Signal delivery instead of UUID** — signal-cli cannot send to its own number (`UNREGISTERED_FAILURE`). Always use the Signal UUID from sessions.json.
3. **Not setting `attach_to_session: true` when the user wants to reply** — without it, replies to the briefing start a fresh session with no context.
4. **Conflicting schedule with existing jobs** — two briefings at different times cause confusion. Clean up old jobs.
5. **Forgetting that cron runs have NO history** — never rely on "as we discussed yesterday." Every cron run starts from scratch.
6. **Duplicate deliver targets** — `deliver: "all"` fans out everywhere and may deliver to unintended platforms (e.g., WhatsApp when the user only wants Signal). Use explicit per-platform delivery for targeting.
7. **Not adding Reddit `site:` syntax properly** — `site:reddit.com/r/SubName` must be the complete query format. Omitting `site:` leads to generic web results, not targeted subreddit content.

## Verification Checklist

- [ ] User confirmed: time, platform, topics, language, format
- [ ] Delivery chat ID resolved (UUID for Signal, phone number for WhatsApp, etc.)
- [ ] Prompt is self-contained (no reliance on convo history)
- [ ] Prompt includes explicit "search even if you think you know" instructions
- [ ] Prompt defines output format with fallback for empty categories
- [ ] `enabled_toolsets` set to `["web"]` (minimal tool scope)
- [ ] `attach_to_session` set to `true` (reply capability)
- [ ] Old conflicting jobs identified and resolved (paused or removed)
- [ ] Reddit sources included with proper `site:reddit.com/r/...` syntax (if applicable)
- [ ] `next_run_at` shows correct date/time
- [ ] Job state is `scheduled`
