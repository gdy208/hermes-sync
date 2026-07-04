# Gateway Platform Setup — Quick Troubleshooting

## WhatsApp

### Symptom : "Unauthorized user: <id> (name) on whatsapp"
**Cause :** User's WhatsApp ID not in the allowlist.

**Fix :**
1. Extract the user ID from the warning log (e.g. `116054462304448@lid`)
2. Add to `~/.hermes/.env`:
   ```
   WHATSAPP_ALLOWED_USERS=116054462304448@lid
   ```
   For multiple: comma-separated
3. Restart gateway: `hermes gateway restart`
4. Verify in logs: `tail -10 ~/.hermes/logs/gateway.log | grep whatsapp`

### Symptom : "WhatsApp enabled but not paired / no creds.json"
**Cause :** WhatsApp bridge not yet linked to a phone.

**Fix :**
1. Run `hermes whatsapp`
2. Scan the QR code from WhatsApp mobile app (Settings → Linked Devices → Link a Device)
3. Wait for "WhatsApp connected" in the terminal
4. Verify: `hermes gateway status` should show `whatsapp: connected`

### Symptom : Bridge exits during shutdown repeatedly
**Cause :** Normal during gateway restarts. Not a concern unless it persists after startup.

**Fix :** No action needed. The bridge auto-restarts.

### Bridge process details
- Binary: `~/.hermes/hermes-agent/scripts/whatsapp-bridge/bridge.js`
- Runs as a subprocess of the gateway (via Node.js)
- Session data: `~/.hermes/whatsapp/session/`
- Mode: `self-chat` (the paired phone sends messages to itself)
- Port: 3000 (internal, between gateway and bridge)

---

## Slack

### Symptom : "not_allowed_token_type"
**Cause :** The token type is wrong. Common issues:
- Using a user token (xoxp-) instead of a bot token (xoxb-)
- Using an app-level token (xapp-) instead of a bot token (xoxb-) for the SLACK_BOT_TOKEN

**Fix :**
1. Verify your Slack App has Socket Mode enabled
2. Bot Token Scopes required: `chat:write`, `app_mentions:read`, `channels:history`, `groups:history`, `im:history`
3. Subscribe to bot events: `app_mention`, `message.channels`, `message.groups`, `message.im`
4. Install the app to workspace, copy the **Bot User OAuth Token** (starts with `xoxb-`)
5. Set in `.env`:
   ```
   SLACK_BOT_TOKEN=xoxb-...
   SLACK_APP_TOKEN=xapp-...
   ```
6. Restart gateway

### Symptom : "Slack channels not listing" in logs
**Cause :** If the bot only works in DMs but fails in channels, the `message.channels` event subscription is missing, or the bot isn't invited to channels.

### Helpful command
```
hermes slack manifest    # View available slash commands for Slack (e.g. /model, /reset, /tools)
hermes slack manifest --write  # Write the manifest file
```

---

## General Gateway Commands

```bash
# Status check
hermes gateway status

# Logs inspection
tail -50 ~/.hermes/logs/gateway.log | grep -E 'whatsapp|slack|Unauthorized|connected|disconnected'

# Restart
hermes gateway restart

# Interactive setup
hermes gateway setup

# Full platform list check
grep -E '✓|✗|warning' ~/.hermes/logs/gateway.log | tail -10
```
