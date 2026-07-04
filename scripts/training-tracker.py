#!/usr/bin/env python3
"""Lecture de l'etat d'avancement de Gedeon pour le cron matinal.
Inclut le suivi des revisions maths/physique."""
import json, os, datetime

STATE_FILE = os.path.expanduser("~/.hermes/training-status.json")
PLAN_FILE = os.path.expanduser("~/.hermes/training-plan-vacances-2026.md")

try:
    with open(STATE_FILE) as f:
        state = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    state = {"current_week": 1, "current_day": 1, "yesterday_status": "unknown",
             "yesterday_note": "", "streak": 0, "plan_started": "2026-06-27",
             "math_topic": "probas"}

today = datetime.date.today().isoformat()

week_subjects = {
    1: "Prise en main Linux",
    2: "Git & Version Control",
    3: "Python pour l'automatisation",
    4: "Docker (fondamentaux)",
    5: "Bash Scripting",
    6: "Réseaux appliqués",
    7: "CI/CD : premiers pas",
    8: "Projet de synthèse",
}

math_rotation = {
    "probas":  {"name": "Probabilités", "next": "analyse",
                "sujet": "variables aléatoires, lois usuelles, espérance, variance"},
    "analyse": {"name": "Analyse",       "next": "algebre",
                "sujet": "dérivées, intégrales, équations différentielles, séries"},
    "algebre": {"name": "Algèbre linéaire", "next": "probas",
                "sujet": "matrices, espaces vectoriels, déterminants, diagonalisation"},
}

week = state.get("current_week", 1)
day = state.get("current_day", 1)
status = state.get("yesterday_status", "unknown")
note = state.get("yesterday_note", "")
streak = state.get("streak", 0)
start = state.get("plan_started", "2026-06-27")
math_topic = state.get("math_topic", "probas")

subject = week_subjects.get(week, f"Semaine {week}")
math_info = math_rotation.get(math_topic, math_rotation["probas"])
math_next = math_info["next"]
math_next_info = math_rotation.get(math_next, math_rotation["probas"])

print(f"TRAINING_STATUS={status}")
print(f"TRAINING_NOTE={note}")
print(f"TRAINING_STREAK={streak}")
print(f"TRAINING_WEEK={week}")
print(f"TRAINING_DAY={day}")
print(f"TRAINING_SUBJECT={subject}")
print(f"TRAINING_DATE={today}")
print(f"TRAINING_MATH_TOPIC={math_info['name']}")
print(f"TRAINING_MATH_SUBJECT={math_info['sujet']}")
print(f"TRAINING_MATH_NEXT={math_next_info['name']}")
print(f"TRAINING_PLAN_STARTED={start}")
