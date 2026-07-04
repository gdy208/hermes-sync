# DevOps Foundations — 8-Week Training Plan

**Target audience:** Beginner students with basic Python, no prior DevOps experience
**Rythme conseillé :** Théorie 3h + Pratique 4-5h + Consolidation 1h = 7-10h/sem
**Objectif final :** Être capable de conteneuriser une application, l'automatiser en CI/CD, et comprendre l'infrastructure nécessaire au déploiement de solutions IA.

---

## Week 1 — Linux Command Line

**Theory (3h)**
- Navigation : ls, cd, pwd, tree
- Manipulation : cp, mv, rm, mkdir, touch
- Lecture : cat, less, head, tail, wc
- Recherche : find, grep, locate
- Permissions : chmod, chown, umask
- Paquets : apt update, apt install, apt remove
- Redirections : |, >, >>, <, tee
- Variables d'environnement : export, $PATH, env

**Practice (4-5h)**
- Exercises : navigate the filesystem, find all .py files, grep for a pattern across log files, write a one-liner that counts lines/functions in a directory
- Mini-challenge : create a directory structure for a project (src/, tests/, docs/, data/), set permissions, create a .env file

**Resources**
- `man <command>` for every command
- https://linuxcommand.org/

---

## Week 2 — Git & Version Control

**Theory (3h)**
- Initialisation : git init, git clone
- Cycle local : add, commit, status, log, diff
- Branches : branch, checkout, switch, merge
- Collaboration : remote, push, pull, fetch
- GitHub : forks, pull requests, issues
- .gitignore, README.md, convention de commit

**Practice (4-5h)**
- Create a repo, make 10+ commits with branches
- Simulate a conflict and resolve it
- Push to GitHub, open a PR (even to your own repo)
- Write a proper README

**Resources**
- https://learngitbranching.js.org/ (interactive)
- Pro Git Book (free)

---

## Week 3 — Python for Automation

**Theory (3h)**
- Révision : listes, dicts, sets, fonctions, classes de base
- Fichiers : open(), read(), write(), with, pathlib
- OS/Subprocess : os.listdir, os.walk, subprocess.run
- Arguments : argparse, sys.argv
- Regex : re.search, re.findall, re.sub
- Logging : logging module

**Practice (4-5h)**
- Script : rename all .jpg files in a folder with a date prefix
- Script : parse /var/log/syslog and count error types
- Script : backup script with argparse (source, dest, compress flag)
- Script : batch download using urllib/requests

**Why this matters for DevOps**
- Automation is the core of DevOps. Python lets you script infrastructure tasks more cleanly than bash.

---

## Week 4 — Docker

**Theory (3h)**
- Images vs containers vs volumes
- docker pull, run, ps, stop, rm, exec, logs
- Dockerfile : FROM, RUN, COPY, CMD, ENTRYPOINT, EXPOSE
- docker-compose.yml : services, volumes, networks, ports
- Registries : Docker Hub, private registries
- Bonnes pratiques : multi-stage builds, .dockerignore

**Practice (4-5h)**
- Dockeriser une app Python Flask simple
- Utiliser docker-compose pour app + base de données
- Construire et tagger une image, la pousser sur Docker Hub
- Lire les logs d'un conteneur, exécuter une commande dans un conteneur actif

**Why this matters for DevOps**
- Docker is the universal packaging format for modern apps, including AI/ML models (TensorFlow Serving, Triton, etc.)

---

## Week 5 — Bash Scripting

**Theory (3h)**
- Shebang, variables, paramètres positionnels ($1, $@, $?)
- Conditions : if, test, [ ], [[ ]]
- Boucles : for, while, until
- Fonctions bash
- exit codes, trap, erreur handling
- sed et awk basiques

**Practice (4-5h)**
- Script : backup.sh avec rotation (garder 7 jours)
- Script : healthcheck.sh (CPU, RAM, disque, services)
- Script : deploy.sh (git pull, build, restart service)
- Créer un alias .bash_aliases et des fonctions shell utiles

---

## Week 6 — Networking Applied

**Theory (3h)**
- Modèle OSI / TCP/IP (rappel)
- Adressage IP, masque, CIDR, ports
- DNS : résolution, dig, nslookup
- HTTP/HTTPS : méthodes, status codes, headers
- Curl avancé : -X, -H, -d, -o, -v
- Diagnostics : ping, traceroute, netstat/ss, nmap basics

**Practice (4-5h)**
- curl une API REST publique (GitHub, OpenWeather, etc.)
- nmap scanner votre machine locale
- Analyser un packet avec tcpdump (basique)
- Configurer un hôte dans /etc/hosts

**Why this matters for DevOps**
- Déployer c'est exposer des services sur le réseau. Comprendre le réseau est non-négociable.

---

## Week 7 — CI/CD with GitHub Actions

**Theory (3h)**
- CI vs CD : concepts et différences
- GitHub Actions : workflow, jobs, steps, runners
- Événements : push, pull_request, schedule
- Actions marketplace : checkout, setup-python, docker/login
- Secrets et variables d'environnement dans GitHub
- Matrix builds, caching, artifacts

**Practice (4-5h)**
- Workflow : lint → test → build sur chaque push
- Workflow : docker build + push sur Docker Hub
- Workflow : déploiement automatique sur un VPS via SSH
- Ajouter des badges de statut au README

---

## Week 8 — Capstone Project

**Objectif :** Intégrer tout ce qui a été appris en un projet complet.

**Projet : Application Python Flask → Conteneurisée → CI/CD → Déployée**

1. Écrire une app Flask minimaliste avec une route API
2. Ajouter des tests unitaires (pytest)
3. Dockerfile multi-stage
4. docker-compose avec base de données
5. Dépot GitHub avec README et .gitignore
6. GitHub Actions workflow : lint → test → build → push image Docker → déploiement
7. Documenter le tout dans un README de qualité

**Livrable :** Un dépôt GitHub public contenant l'infrastructure complète du projet.

---

## Progression pédagogique

Chaque semaine s'appuie sur la précédente :
Linux → Git → Python → Docker → Bash → Réseaux → CI/CD → Synthèse

Les cours S5 (Algorithmique, C, Python, OS) et S6 (Réseaux, Routage, Java) sont naturellement renforcés par ce parcours.

## Communication

- L'étudiant rend compte sur WhatsApp/Slack de ce qu'il a appris
- L'agent corrige les exercices, donne des retours, répond aux questions bloquantes
- Une fois la semaine validée, on passe à la suivante
