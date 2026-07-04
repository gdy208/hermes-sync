#!/usr/bin/env python3
import json, sys, os

sys.path.insert(0,'/usr/local/lib/hermes-agent')
from tools.discord_tool import discord_admin_handler as d

guild = '1521183696974119062'

def create_cat(name):
    r = json.loads(d(action='create_channel', guild_id=guild, name=name, channel_type=4))
    print(f"  ✅ Catégorie «{name}» → ID {r.get('channel_id')}")
    return r.get('channel_id')

def create_txt(name, topic, parent):
    r = json.loads(d(action='create_channel', guild_id=guild, name=name, channel_type=0, topic=topic, parent_id=parent))
    print(f"  ✅ Salon  «{name}» → ID {r.get('channel_id')}")
    return r.get('channel_id')

print("=" * 50)
print("🏗️  Création de la structure du serveur")
print("=" * 50)

# === 1. INPHB S5 ===
print("\n📚 INPHB S5")
s5 = create_cat("📚 INPHB S5")
create_txt("📖 algo-c-python",
    "Algorithmique, langage C, Python, systemes d'exploitation - S5 ESI INPHB", s5)
create_txt("📐 maths",
    "Probabilites, Analyse, Algebre - Revisions et cours S5", s5)
create_txt("📡 signaux",
    "Traitement du signal - Cours et exercices S5", s5)

# === 2. Revisions et Pratique ===
print("\n📝 Revisions et Pratique")
rev = create_cat("📝 Revisions et Pratique")
create_txt("📅 revisions",
    "30 min/jour - Rotation: Probas puis Analyse puis Algebre - Remise a niveau rentree S5", rev)
create_txt("✏️ exercices",
    "Exercices en cours - Algo, Python, Maths, Signaux - Correction pas a pas", rev)

# === 3. DevOps et Lab (categorie existante) ===
print("\n🚀 DevOps et Lab")
devops_cat = "1521197882181423105"
create_txt("🐳 docker",
    "Docker, conteneurs, compose, orchestration - Labs et experiences", devops_cat)
create_txt("⚡ ci-cd",
    "CI/CD avec GitHub Actions - Pipelines, automatisation, deploiement", devops_cat)

# === 4. Projets et Ressources ===
print("\n💡 Projets et Ressources")
proj = create_cat("💡 Projets et Ressources")
create_txt("🎯 projets",
    "Mes projets DevOps/IA - Suivi, architecture, decisions techniques", proj)
create_txt("📚 cheatsheets",
    "Antiseches, commandes utiles, snippets - Linux, Git, Docker, Python, Bash", proj)
create_txt("🔗 liens",
    "Liens utiles, documentation, articles, tutos a sauvegarder", proj)

# === 5. Hermes ===
print("\n🤖 Hermes")
hermes = create_cat("🤖 Hermes")
create_txt("🧪 labs",
    "Experiences, automatisations, config de mon assistant Hermes", hermes)

print("\n" + "=" * 50)
print("✅ Structure creee avec succes !")
print("=" * 50)
