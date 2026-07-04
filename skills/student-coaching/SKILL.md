---
name: student-coaching
description: "Guide a student through a structured learning journey: profile, training plan, adaptive daily reminders via cron+script+state-file, and progress tracking with conversation feedback loop."
category: coaching
---

# Student Coaching

## When to use
- A user wants to learn a new skill domain and needs a structured plan
- You need to create a multi-week training curriculum aligned with school/academic program
- Setting up automated daily motivation/reminders with progress-adaptive messages
- A user wants learning tracked and reminders adapted to their daily progress
- Combining skill training (DevOps, coding) with foundational revision (math, physics) in one daily routine

## Workflow

### 1. Profile the learner
Ask structured open-ended questions (do NOT propose options the user must choose from — let them answer freely):
- Background, current studies, institution
- Career goals and timeline
- Current skill level and tools used
- Operating system and technical environment
- Learning style (reading, hands-on, video…)
- Time available per week (holidays vs school period)
- Preferred name / how to address them

Save all responses to user memory entries.

### 2. Design the training plan
- Break into weekly modules (8 weeks recommended for holiday blocks)
- Each week has a clear topic and hands-on objectives
- Align with the learner's academic program where possible to reinforce coursework
- Include revision of foundational topics (math, physics) if relevant
- Save plan as `~/.hermes/training-plan-vacances-YYYY.md`

### 3. Set up the state file
Create `~/.hermes/training-status.json`:
```json
{
  "current_week": 1,
  "current_day": 1,
  "yesterday_status": "unknown",
  "yesterday_note": "",
  "streak": 0,
  "plan_started": "YYYY-MM-DD",
  "plan_file": "/home/user/.hermes/training-plan-vacances-YYYY.md",
  "math_topic": "probas"
}
```

### 4. Create the tracker script
Write `~/.hermes/scripts/training-tracker.py` that:
- Reads `training-status.json`
- Maps week numbers to subject names
- Implements a cyclic rotation for revision topics (e.g. probas → analyse → algebre)
- Outputs env-var-style lines (e.g. `TRAINING_STATUS=completed`) that the cron job injects as context

### 5. Create the adaptive cron job
Use the `cronjob` tool with:
- `schedule`: `0 7 * * *` (daily at 7am)
- `deliver`: `all` (fans out to WhatsApp + Slack)
- `script`: `training-tracker.py` (relative path resolves under `~/.hermes/scripts/`)
- `prompt`: full learner context + instructions to generate a 3-part message (long-term goals reminder → status-adapted encouragement → today's objectives split: skill topic + revision topic)

**Important**: Check `cronjob action='list'` first and remove any duplicate cron jobs on the same schedule to avoid double-delivery.

### 6. Feedback loop
- Learner reports progress via conversation (WhatsApp, Slack, or CLI)
- Update `training-status.json` in response:
  - `completed` → increment `current_day`, reset to day 1 and increment `current_week` when week is done, increase `streak`
  - `partial` → keep same day, note what remains, partial streak handling
  - `skipped` → reset streak to 0
  - Also rotate `math_topic` when the learner completes a full topic day
- Next morning's cron reads updated state and adapts the message

## State transitions for `yesterday_status`

| Learner says | Set yesterday_status to | Effect on message |
|---|---|---|
| "Fini" / "Done" | `completed` | Félicitations, nouveau sujet, streak++ |
| "À moitié" / "Half" | `partial` | Encourage, objectif allégé |
| "Pas fait" / "Skipped" | `skipped` | Pas de pression, nouveau départ |
| (no report) | `unknown` | Message général |

## Revision rotation pattern
For learners who need foundational review (e.g. pre-engineering math):
```
probas → analyse → algebre → probas → …
```
Implement as a dict in the tracker script with each topic having a `next` pointer. Daily 30 min per topic, integrated in the same morning message.

## Pitfalls
- **Duplicate cron jobs**: Always `cronjob action='list'` before creating. Remove old/identical ones first.
- **Cron jobs cannot ask questions**: Feedback must come from conversation, not from the cron run itself.
- **`deliver=all` requires connected platforms**: Verify WhatsApp/Slack are connected and user is whitelisted before creating.
- **State file paths**: Use `os.path.expanduser("~/.hermes/...")` in scripts so they work regardless of `$HOME`.
- **Script shebang**: Make tracker scripts executable or use `/usr/bin/env python3` shebang.
- **Language**: If the learner speaks French, the cron prompt and responses should be in French for consistency.
- **SOUL.md for language enforcement**: Set the agent's default language via `~/.hermes/SOUL.md` (loaded on every session start). Add explicit instructions like `Always respond in French unless the user explicitly writes in another language.` This is more reliable than memory alone and survives session resets.

### 7. Code reading tutorials (walking through existing code)

When the student wants to learn by reading an existing codebase or project file-by-file — signal phrases: "explique moi le code", "on lit le code ensemble", "tu m'accompagnes pas à pas".

**Workflow:**
1. **Read first** — Use `read_file()` to load the code. Never explain from memory or a summary.
2. **Choose explanation depth based on student level**:
   - **Line-by-line (débutant)** — For absolute beginners or first encounter with the domain. Walk through every line in order, explaining each API call and its role before moving on. Use concrete analogies (socket = prise téléphonique, accept() = standardiste qui décroche, listen() = mettre le téléphone en mode sonnerie).
   - **Top-down (intermédiaire)** — For students with some domain knowledge. Start with a high-level analogy, then drill into each construct. Layer order: mental model → API purpose → parameter details → protocol semantics.
3. **Protocol side-by-side** — For network/protocol code, show the raw protocol text in a paired view:
   ```
   -- Requête (curl) --                  |  -- Réponse (serveur) --
   GET / HTTP/1.1                        |  HTTP/1.1 200 OK
   Host: localhost:8888                  |
   User-Agent: curl/...                  |  Hello, World!
   ```
   Visually connecting request format to response format reinforces how the protocol works.
4. **Run and observe** — Execute the code immediately. Show real output (stdout, server logs, curl responses). Connect the output back to the concepts just explained.
5. **Concept summary table** — Recap the lesson in a structured table:
   | Concept | Rôle |
   |---|---|
   | **Socket** | Prise réseau — l'interface entre le programme et le réseau |
   | **TCP** | Protocole fiable avec connexion |
   | **`bind()`** | Associe le socket à une adresse + port |
   Each row ties one API call to its conceptual role, creating a compact reference the student can revisit.
6. **Offer branching next steps** — Let the student choose: deepen a concept, modify the code together, or move to the next lesson. Format as a short numbered list, not an open question.

**Server/network code testing workflow** (Hermes CLI environment):
```
terminal(background=true)       → start server
terminal("curl -v ...")         → test with real client (use -v to show raw HTTP exchange)
process(action="log")           → check server stdout (captures print() output from server)
process(action="kill")          → clean up when done
```
This avoids the `&` backgrounding limitation in foreground terminal commands.

**Debugging pattern — server fails to start (port conflict):**
```
1. ss -tlnp | grep <PORT>         # check what owns the port
2. fuser -k <PORT>/tcp            # kill the orphan process
3. sleep 1                         # wait for TIME_WAIT to clear
4. restart server in background
5. process(action="log")           # verify no startup error
```
Common cause: previous server instance (from a crashed or timed-out attempt) left the socket in TIME_WAIT. SO_REUSEADDR helps but does not always prevent the error when the old socket is still owned by a live process.

**Key principles:**
- Never describe what you *could* do — execute first, explain while the output is fresh
- For network/socket code: start from OSI transport layer (TCP reliable vs UDP connectionless), then Python socket API, then protocol text (HTTP request/response side by side)
- Always verify the code runs before teaching from it — a broken example undermines the explanation
- When a server returns "Empty reply from server" (curl exit 52), suspect either: (a) server crashed on bind/start, (b) response was malformed, or (c) server was killed before handling the request. Check process action=log first.
- After killing a server background process, confirm with ss -tlnp | grep <PORT> that the port is free before retrying.

## User interaction style

When coaching Gédéon (and students who show similar signals):
- **Execute actions directly** rather than giving step-by-step instructions. If you can run a command, create a file, or set up infrastructure yourself, do it. The user will ask for help if they want to follow along manually.
- Signal: "tu peux faire ça toi meme, non ?" = "why are you telling me when you could just do it."
- Use `terminal()` to run commands, `patch()` / `write_file()` to create files, and `cronjob()` to schedule jobs — don't describe the steps.

## Deployment migration

When the student moves their Hermes gateway from PC to another device (e.g., Android phone via Termux), the coaching pipeline must be transferred:

### Files to transfer
```
cron/              → scheduled jobs (cron jobs live in ~/.hermes/cron/)
scripts/           → training-tracker.py and other helper scripts
training-status.json  → current progress state
memories/          → USER.md, MEMORY.md (learner profile + session memory)
SOUL.md            → language and identity preferences
```

### Transfer method
1. On the source machine: `cd ~/.hermes && tar czf hermes-config.tar.gz cron/ scripts/ training-status.json SOUL.md memories/`
2. Serve via HTTP: `python3 -m http.server 8888` (in `~`)
3. On the target machine (Termux): `curl -O http://<source-ip>:8888/hermes-config.tar.gz && tar xzf hermes-config.tar.gz -C ~/.hermes/`
4. Restart gateway: `hermes gateway restart`

### When target is Termux (Android phone)
- Use `termux-wake-lock` to prevent deep sleep after starting the gateway
- Disable battery optimization for Termux (Settings → Apps → Termux → Battery)
- Enable notifications (Android kills apps without persistent notification)
- Lock Termux in the recent-apps overview
- First install compiles Rust/C packages from source (~20-40 min, one-time cost)
- Multi-session: swipe from left edge of screen for a new terminal while gateway runs in background
- Gateway QR code linking on the same device: screenshot the QR code → WhatsApp → Linked Devices → pick from gallery
