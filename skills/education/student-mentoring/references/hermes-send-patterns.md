# hermes send — Command Reference for Automated Messaging

`hermes send` pipes text from any script/command to any messaging platform Hermes is already configured for. It reuses the gateway's platform credentials — no LLM, no agent loop, no running gateway required for bot-token platforms.

## Discovery

```bash
hermes send --list                        # all targets
hermes send --list slack                  # filter by platform
```

Output format:
```
Slack:
  slack:general (channel)
Whatsapp:
  whatsapp:Gédéon (dm)
```

## Sending

### From stdin (preferred for multi-line)
```bash
cat << 'MESSAGE' | hermes send --to slack:general --subject "🌅 Bonjour"
Line 1
Line 2
MESSAGE
```

### From a file
```bash
hermes send --to slack:general --subject "[Report]" --file /tmp/report.md
```

### Single line
```bash
hermes send --to slack:general "deploy finished"
```

## Target syntax

| Format | Example | Meaning |
|--------|---------|---------|
| `platform` | `telegram` | home channel |
| `platform:chat_id` | `telegram:-1001234567890` | specific chat |
| `platform:chat_id:thread_id` | `telegram:-1001234567890:17585` | specific thread |
| `platform:#channel-name` | `discord:#ops` | channel by name |
| `platform:username` | `whatsapp:Gédéon` | DM by display name |

## Attachments

```bash
hermes send --to telegram "MEDIA:/tmp/chart.png"
```

## Exit codes

| Code | Meaning |
|------|---------|
| 0 | Sent successfully |
| 1 | Delivery/backend error |
| 2 | Usage error (bad target, missing message) |

## Pitfalls

- **`--subject` prepends a header line** before the message body. Use it for titles or emoji headers.
- **`--quiet` suppresses stdout on success** — combine with exit-code checks for silent cron jobs.
- **Platform names are lowercase** in the target string: `slack:`, `whatsapp:`, `telegram:`, `discord:`.
- **DM targets use the contact's display name** as shown in `--list`, not a phone number or email.
