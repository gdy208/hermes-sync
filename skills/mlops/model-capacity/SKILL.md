---
name: model-capacity
description: "Determine if a model can run on given hardware: sizing RAM vs disk, MoE vs dense semantics, quantization tiers, and companion tools (llmfit, llm-checker)."
version: 1.0.0
author: Hermes Agent
tags: [sizing, capacity, moe, dense, quantization, ram, disk, hardware, compatibility, planning]
---

# Model Capacity Planning

Sizing a model for a user's hardware without guessing. Covers the common pitfall of confusing disk space with RAM, explains MoE vs dense memory semantics, and provides quick estimation formulas.

## When to use

- User asks "can I run model X on my machine?"
- User provides RAM/VRAM and asks which quant fits
- User is confused about why a 37 GB GGUF file "needs less RAM than its file size" (MoE)
- User wants to know what model to download for their hardware
- User asks for a CLI tool that auto-analyzes hardware and recommends models

## Core Concepts

### Disk vs RAM — La confusion n°1

**Le fichier GGUF est stocke sur le disque.** Sa taille (ex: 36,9 Go pour `Qwen3.6-35B-A3B-Q8_0.gguf`) est l'espace disque necessaire, PAS la RAM.

**RAM utilisee en inference :** avec `mmap` (par defaut dans llama.cpp) :
- Le fichier est mappe en memoire virtuelle — l'OS ne charge en RAM physique que les pages effectivement accedees
- **Dense** : tous les parametres sont actifs a chaque token → RAM ~= taille du fichier
- **MoE** : seuls les K experts actifs par token sont charges en RAM (~3B parametres sur 35B pour Qwen3.6-35B-A3B). RAM reelle ~5-8 Go meme si le fichier fait 37 Go.

**Table recap :**

| Type | Exemple | Fichier disque | RAM necessaire |
|------|---------|---------------|----------------|
| Dense | Llama-3-70B-Q8 | ~70 Go | ~70 Go |
| MoE | Qwen3.6-35B-A3B-Q8 | ~37 Go | ~5-8 Go |
| MoE | Qwen3.6-35B-A3B-Q4 | ~22 Go | ~3-5 Go |
| Dense | Llama-3.2-3B-Q8 | ~3 Go | ~3 Go |

### Quick sizing formula

Pour un modele dense : **RAM ≈ params_B × bytes_per_param × 1,1 (overhead)**

| Quant | Bytes/param |
|-------|------------|
| Q2 | 0,31 |
| Q3 | 0,38 |
| Q4 | 0,5 |
| Q5 | 0,63 |
| Q6 | 0,75 |
| Q8 | 1,0 |
| F16 | 2,0 |

Exemple : Llama-3-8B-Q4_K_M → 8 × 0,5 × 1,1 ≈ **4,4 Go RAM**

Pour un MoE, la RAM est ~**params_actifs × bytes_per_param × 2** (couches denses + cache). Le fichier disque, lui, fait params_total × bytes_per_param.

### Que regarder en priorite

1. **RAM disponible** (pas RAM totale) → `free -h` regarder la ligne `disponible`
2. **Swap** → si present, peut absorber les debordements mais reduit les perfs
3. **Stockage libre** → `df -h ~`
4. **CPU/GPU** → nombre de coeurs, presence CUDA/ROCm/Metal

### Companion tools

Si l'utilisateur ne veut pas calculer manuellement, suggerer ces CLI specialisees :

- **`llmfit`** — analyse le hardware, scanne les modeles disponibles sur HF, et classe par qualite/vitesse compatibles
  - Install : `pip install llmfit` ou `npx llmfit`
  - Usage : `llmfit` (auto-detect)
- **`llm-checker`** — scan le hardware et dit quels LLM/sLLM peuvent tourner, avec integration Ollama
  - Install : `pip install llm-checker`
  - Usage : `llm-checker`

Ces outils ne sont pas installés par defaut — ils sont optionnels.

## Grammaire de reponse

Quand un utilisateur demande si un modele tourne sur sa machine :

1. **Verifier les specs** de sa machine (RAM, stockage, CPU/GPU) avec `free -h`, `df -h ~`, `nproc`, `nvidia-smi`
2. **Trouver le modele** sur HF (tree API ou local-app)
3. **Distinguer clairement** stockage et RAM :
   - "Le fichier fait X Go sur le disque — verification que t'as assez de place"
   - "En RAM, avec mmap, le modele utilisera environ Y Go en inference"
4. **Si ca ne tient pas** : proposer une quantification plus aggressive ou un modele plus petit
5. **Si l'utilisateur est perdu** : suggerer llmfit/llm-checker

## Pitfalls

1. **"Le fichier fait 37 Go donc j'ai besoin de 37 Go de RAM"** — Faux pour les MoE. Expliquer le mmap et l'activation sparse des experts.
2. **"Ma machine a 16 Go de RAM, donc je peux charger un 70B en Q4"** — Non, un dense 70B-Q4 fait ~35 Go de fichier ET de RAM. Verifier le type (dense vs MoE).
3. **"J'ai 8 Go de RAM libre mais le modele fait 10 Go, ca va passer avec le swap"** — Possible mais lent. Le swap evite le crash mais les perfs degradent fortement.
4. **Oublier le cache** — le KV cache pour longs contextes peut ajouter plusieurs Go. Pour un contexte de 32K tokens, compter ~1-2 Go supplementaires.
5. **Confondre VRAM et RAM** — sur GPU, le modele doit tenir dans la VRAM. Le CPU mmap ne s'applique pas. Un modele qui depasse la VRAM + RAM partagee ne tourne pas sur GPU.
