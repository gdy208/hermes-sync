---
name: build-your-own-curriculum
description: "Recommend and set up a structured learning path from the build-your-own-x repo — match projects to the user's stack (Python, Go, etc.) and goal (DevOps, backend, systems), set up the workspace, and push to their GitHub."
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [build-your-own, curriculum, learning-path, devops, python, hands-on]
    related_skills: [github-repo-management, github-auth, plan]
---

# build-your-own-curriculum

Curate a multi-project learning path from the [build-your-own-x](https://github.com/codecrafters-io/build-your-own-x) repo — match projects to the user's tech stack and learning goal, then set up a ready-to-code workspace.

## When to use

- User says "I want to learn X by building from scratch"
- User asks "what should I build to learn Y"
- User wants a structured hands-on path (not just a list of tutorials)
- User discovers the build-your-own-x repo and asks for guidance

## Workflow

### Phase 1 — Understand the user

Ask or infer:
- **Goal**: What domain? (DevOps, backend, systems, networking, databases...)
- **Stack**: What languages/tools do they already know? (Python, Go, JS, C...)
- **Level**: Beginner / intermediate / advanced
- **Constraints**: No C, no Docker, limited time, etc.

### Phase 2 — Select projects from build-your-own-x

Fetch the repo README and scan for projects matching stack + goal.

**Selection criteria:**
- Prefer projects in the user's known languages (or adjacent ones they can follow)
- Order by dependency: each project should build concepts the next one needs
- Max 4-5 projects for a focused path (more = overwhelm)

**For DevOps with Python (the canonical path):**

| Phase | Project | Repo / URL | Why |
|-------|---------|-----------|-----|
| 1 | HTTP Server | [rspivak/lsbaws](https://github.com/rspivak/lsbaws) — tutorial: https://ruslanspivak.com/lsbaws-part1/ | Sockets, TCP, HTTP protocol — foundation for everything |
| 2 | Mini Redis | [coleifer/simpledb](https://github.com/coleifer/simpledb) — tutorial: https://charlesleifer.com/blog/building-a-simple-redis-server-with-python/ | Wire protocol, key-value store, multi-client, persistence |
| 3 | Docker (mocker) | [tonybaloney/mocker](https://github.com/tonybaloney/mocker) | Linux containers, namespaces, cgroups — pure Python |
| 4 | Git | [thblt/write-yourself-a-git](https://github.com/thblt/write-yourself-a-git) — tutorial: https://wyag.thb.lt/ | Objects, hashes, trees, versioning internals |
| 5 | CI System | [aosabook/500lines](https://github.com/aosabook/500lines) — chapter: ci/ | Automation, distributed systems, pipelines |

**Alternative tracks:**
- **Backend/API**: HTTP Server → Mini Redis → Web framework from scratch
- **Systems/C**: Shell → Memory allocator → Tiny OS — requires C
- **Go DevOps**: HTTP Server (Go) → Docker (Go) → Kubernetes from scratch

### Phase 3 — Clone and prepare workspace

```bash
# Create workspace
mkdir -p ~/build-your-own-<goal>
cd ~/build-your-own-<goal>

# Clone each project (numbered by order)
git clone <url-1> 01-<project-name>
git clone <url-2> 02-<project-name>
# ... etc
```

If the user wants a **single repo on their GitHub** (e.g., to pull on another machine):

```bash
# Remove embedded .git from each subdirectory
rm -rf 01-*/.git 02-*/.git 03-*/.git 04-*/.git 05-*/.git

# Init a fresh repo
git init
git checkout -b main
git add -A
git commit -m "Initial commit: <goal> learning path"

# Create remote and push (requires gh CLI authenticated)
gh repo create <user>/build-your-own-<goal> --private \
  --description "<goal> learning path - <project list>" \
  --source . --remote origin --push
```

### Phase 4 — Teach the path

For each project, explain:
1. **What it builds** (1 sentence)
2. **What concepts it teaches** (the real value)
3. **Link to user's existing knowledge** ("souviens-toi, en cours Cisco t'as vu TCP — ici tu vas le coder")
4. **How it connects to the next project**

Let the user choose: binge the path alone or be walked through step by step.

## Pitfalls

- Don't recommend C projects to Python-only users — the syntax fight kills motivation
- Don't recommend too many projects. 4-5 max for a coherent path
- The 05-ci-system repo (aosabook/500lines) is huge and contains many unrelated chapters. Point user specifically to `ci/` directory
- When consolidating into a single repo, remember to strip `.git` from cloned subdirectories first, or git will reject the push
- The Redis blog post has code inline — link to the [gist](https://gist.github.com/coleifer/dbbedc287605dcc22990a6e549de9f36) or the simpledb repo directly

## Related

- [github-repo-management](../github/github-repo-management/): For gh auth and repo creation details
- [plan](../software-development/plan/): For planning mode when the user wants a structured approach
