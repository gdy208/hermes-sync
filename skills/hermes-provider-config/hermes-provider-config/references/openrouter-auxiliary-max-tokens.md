# OpenRouter — Auxiliary calls and max_tokens billing bug

## Symptom

After an agent response, the automatic title generation fails with:

```
Auxiliary title generation failed: HTTP 402: This request requires more credits,
or fewer max_tokens. You requested up to 65536 tokens, but can only afford 11602.
```

This happens even when the OpenRouter credit balance is positive, because the
**estimated cost** of 65536 output tokens exceeds the available balance.

## Root cause

In `agent/auxiliary_client.py`, the function `_build_call_kwargs` (line 5728)
builds the API request parameters. When `max_tokens` is provided (e.g., 500 for
title generation), it only forwards it to providers that require it:

- Anthropic-compatible endpoints (line 5793)
- NVIDIA NIM (line 5794)

For all other providers — including **OpenRouter** — the `max_tokens` parameter
is silently dropped. When omitted, OpenRouter defaults to the model's maximum
output (65536 tokens for DeepSeek V4 Flash), and bills the estimated cost
accordingly. If the account has fewer credits than the max-token estimate, the
request is rejected with HTTP 402.

## Fix applied

In `_build_call_kwargs`, the condition at line 5792 was extended to include
OpenRouter:

```python
# Before:
if (
    _is_anthropic_compat_endpoint(provider, _effective_base)
    or _is_nvidia_nim
):
    kwargs["max_tokens"] = max_tokens

# After:
if (
    _is_anthropic_compat_endpoint(provider, _effective_base)
    or _is_nvidia_nim
    or _provider_norm == "openrouter"
    or base_url_host_matches(_effective_base, "openrouter.ai")
):
    kwargs["max_tokens"] = max_tokens
```

### File modified

`/usr/local/lib/hermes-agent/agent/auxiliary_client.py` — inside the Hermes venv
`site-packages`.

## Important caveat

**This patch lives in site-packages and will be overwritten** by any of:

- `hermes update`
- `pip install --upgrade hermes-agent`
- Re-installation of the Hermes package

After any of these, the fix must be re-applied. The permanent solution is to
contribute the patch upstream to the `hermes-agent` repository.

## Broader impact

This change forces `max_tokens` on ALL auxiliary calls routed through OpenRouter
(title generation, context compression, web extraction, etc.). The value passed
by each caller is respected — for title generation it's 500, compression uses a
calculated budget, and so on. This is safe because:

1. Title generation already passes `max_tokens=500` (hardcoded in
   `title_generator.py` line 85)
2. Context compression calculates its budget from available context window
3. The `call_llm` function (line 5922) receives and forwards the task-specific
   `max_tokens`

## Related observations

- `auxiliary_max_tokens_param` (line 5043) handles `max_completion_tokens` for
  direct OpenAI and GitHub Copilot, but is **not called** by `_build_call_kwargs`.
  This divergence means OpenAI-direct auxiliary calls also don't get an explicit
  cap. This is a separate, lower-severity issue since OpenAI bills post-usage (not
  pre-estimate).
- The same bug could affect any provider that pre-estimates cost based on
  `max_tokens` — OpenRouter is the only known case as of July 2026.
