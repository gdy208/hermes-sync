---
name: local-llm-ops
description: "Build, run, and integrate local LLM inference (llama.cpp) with AI agents (Hermes) — compile with BLAS, download GGUFs, configure custom providers, manage multiple models, test via API."
---

# Local LLM Operations

Build, run, and integrate local LLM inference with AI agents. Covers the full lifecycle from compilation to agent integration.

## When to use

- User wants to run LLMs locally on CPU (no GPU)
- User wants a local fallback for Hermes Agent (offline mode)
- User wants to download and switch between multiple local models
- User asks "what models can I run on my machine?" (defer to `model-capacity` skill for sizing, then use this skill for setup)

## Prerequisites

- Linux x86_64 with AVX2 support
- ~8+ GB RAM recommended for 7-8B models in Q4
- 10+ GB free disk per model
- `libopenblas-dev`, `cmake`, `build-essential`

## Workflow

### 1. Build llama.cpp with BLAS

```bash
git clone https://github.com/ggerganov/llama.cpp --depth 1
cd llama.cpp
cmake -B build -DLLAMA_BLAS=ON -DLLAMA_BLAS_VENDOR=OpenBLAS
cmake --build build -j4 --target llama-server
```

Key: `-DLLAMA_BLAS=ON` gives ~2x speedup on CPU. `--target llama-server` builds only what's needed.

### 2. Download GGUF models

Use huggingface hub or direct curl:

```bash
# Via huggingface-hub Python (recommended)
pip install huggingface-hub

huggingface-cli download bartowski/Qwen_Qwen3-8B-GGUF \
  --include "Qwen_Qwen3-8B-Q4_K_M.gguf" \
  --local-dir ~/models/

# Or direct curl (multiple in parallel)
curl -L -o ~/models/Qwen3-8B-Q4_K_M.gguf \
  "https://huggingface.co/bartowski/Qwen_Qwen3-8B-GGUF/resolve/main/Qwen_Qwen3-8B-Q4_K_M.gguf" &
```

Monitor progress with `ls -lh ~/models/` and `ps aux | grep curl`.

### 3. Recommended models for CPU (AVX2, ~8 GB RAM free)

| Usage | Model | Quant | RAM | Tok/s |
|-------|-------|-------|-----|-------|
| General + tutor | Qwen3-8B | Q4_K_M | ~5 GB | 1-2 tok/s |
| Code | Qwen2.5-Coder-7B | Q4_K_M | ~4.5 GB | 1-2 tok/s |
| Fast queries | Llama-3.2-3B | Q8_0 | ~3.5 GB | 0.5-1 tok/s |

### 4. Launch server

```bash
~/llama.cpp/build/bin/llama-server \
  -m ~/models/Qwen3-8B-Q4_K_M.gguf \
  --host 127.0.0.1 --port 8080 \
  --ctx-size 8192 --threads 8 \
  --parallel 1 --cont-batching
```

Test:
```bash
curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"Test"}],"max_tokens":50}'
```

### 5. Integrate with Hermes Agent

```bash
hermes config set custom_providers '[{"name":"local","base_url":"http://localhost:8080/v1"}]'
```

Then inside a Hermes session:
```
/model local --provider custom:local
```

To set a shorter context length suitable for local models:
```
hermes config set model.context_length 8192
```

### 6. Multi-model management script

Create `~/.local/bin/llama-serve` (or `~/.hermes/scripts/llama-serve`):

```bash
#!/bin/bash
MODEL=${1:-qwen3}
PORT=${2:-8080}
case $MODEL in
  qwen3)   F=~/models/Qwen3-8B-Q4_K_M.gguf    ;;
  coder)   F=~/models/Qwen2.5-Coder-7B-Q4_K_M.gguf ;;
  llama3)  F=~/models/Llama-3.2-3B-Q8_0.gguf  ;;
  *) echo "Models: qwen3, coder, llama3"; exit 1 ;;
esac
exec ~/llama.cpp/build/bin/llama-server -m "$F" --host 127.0.0.1 --port "$PORT" \
  --ctx-size 8192 --threads 8 --parallel 1 --cont-batching
```

Add to `~/.bashrc`: `alias llama-serve="~/.hermes/scripts/llama-serve"`

## Performance on CPU (i5-8365U实测)

| Model | Quant | Size | Prompt tok/s | Gen tok/s |
|-------|-------|------|-------------|-----------|
| Qwen3-8B | Q4_K_M | 4.7 GB | 3.0 tok/s | 1.5 tok/s |
| Qwen2.5-Coder-7B | Q4_K_M | 4.4 GB | ~3 tok/s | ~1.5 tok/s |
| Llama-3.2-3B | Q8_0 | 3.2 GB | 3.8 tok/s | 0.7 tok/s |

**Note**: The 3B Q8_0 is slower at generation than the 8B Q4_K_M because Q8 uses full 8-bit precision (3.2 GB for 3B = 1.07 GB/1B vs 4.7 GB for 8B = 0.59 GB/1B for Q4_K_M). The Q8 model benefits from a smaller prompt processing cost but generates denser. For this specific CPU generation, Q4_K_M gives better total throughput per GB of model.

On a weaker CPU (4C/8T Whiskey Lake), expected generation speed is **1-3 tok/s** for 7-8B models — usable for text tasks but not interactive chat. The 3B Q8_0 is not faster for generation because Q8 is compute-bound on this hardware.

## Pitfalls

- **Port 8080 occupied by docker-proxy**: Common on machines running containers. docker-proxy binds `127.0.0.1:8080` as root and cannot be killed with `fuser -k`. Check with `ss -tlnp | grep 8080`, use ports 8083, 8084, etc.
- **LLM too slow**: Reduce context size (`--ctx-size 4096`), lower threads (`--threads 4`), or use a smaller model. First prompt is always slowest (model loading into RAM + prompt processing).
- **Hermes context_length too large for local model**: Set `model.context_length: 8192` in Hermes config (not in provider settings — Hermes reads it from the top-level `model.context_length`).
- **Hermes ignores provider-level context_length**: The `context_length` must be set at `model.context_length`, NOT in `providers.*.models.*.context_length`.
- **Out of memory**: Close browsers/IDEs, check `free -h` before launching. Models in Q4_K_M need ~0.6 GB per 1B params. Qwen3-8B Q4_K_M uses ~4.7 GB disk, ~5+ GB RAM at runtime.
- **Model doesn't start**: Check `~/.config/wireplumber/wireplumber.conf.d/` for conflicting configs. The system user-level cron may be starting a conflicting process. Use `local-ai status` to check ports before starting.
- **Hermes config format**: Custom providers use `custom:<name>` as the provider name, not `custom`. Example: `/model local-qwen --provider custom:local-qwen`.

## Related

- `llama-cpp` skill — building, running, HF Hub discovery for llama.cpp
- `model-capacity` skill — sizing models for hardware
- `huggingface-hub` skill — HF Hub search and download
- `scripts/local-ai.sh` — multi-model management script (start/stop/status/switch/list)
