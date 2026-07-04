# Options de déploiement 24/7 pour étudiants

Quand le PC de l'étudiant est éteint, Hermes ne répond plus sur WhatsApp/Slack.
Ce document répertorie les solutions pour garder le gateway actif en permanence,
classées par coût et accessibilité pour un étudiant.

## Le problème

Hermes tourne sur la machine locale de l'étudiant. Gateway, cron, et sessions
meurent avec le PC. Solution : héberger Hermes quelque part qui reste allumé 24/7.

## Tableau comparatif

| Option | Coût | RAM/CPU | Points forts | Points faibles |
|--------|------|---------|-------------|----------------|
| **Termux (Android)** | $0 | RAM du tel | Gratuit, tel toujours allumé, officiellement supporté | Consomme la batterie, Android peut tuer le processus, pas de Docker |
| **Oracle Cloud Free Tier** | $0 | Jusqu'à 4 CPU / 24 GB RAM | Spécifications énormes, gratuit | Instances ARM difficiles à obtenir (régions saturées), carte bleue obligatoire |
| **GitHub Student Pack → Azure** | $0 | VM basique (B1s) | $100 de crédit = ~15 mois gratuits | Expire après épuisement du crédit |
| **GitHub Student Pack → DigitalOcean** | $0 (jusqu'à juil. 2026) | $200 de crédit | $200 = 12 mois gratuits | **Prend fin le 31 juillet 2026** |
| **Hetzner CX22** | ~3.79€/mois | 2 vCPU / 2 GB RAM | Fiable, toujours dispo, excellent rapport qualité/prix | Payant (~2500 FCFA/mois) |

## Option recommandée sans budget : Termux

### Pourquoi Termux

- Le téléphone est déjà allumé 24/7 et connecté (4G/WiFi)
- Aucun achat, aucun abonnement
- Installation officiellement supportée par Hermes (bundle `.[termux]`, `pkg` manager)
- Le gateway WhatsApp peut être configuré et lancé normalement

### Installation

**Prérequis :** Installer Termux depuis **F-Droid** (pas Google Play — version obsolète).
Si tu ne vois pas Termux sur F-Droid, télécharge l'APK directement depuis
le site F-Droid (https://f-droid.org/packages/com.termux/) ou depuis
les GitHub Releases officielles (https://github.com/termux/termux-app/releases/latest).

```bash
# Mise à jour des paquets
pkg update -y && pkg upgrade -y

# Installation Hermes (one-liner officiel)
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash

# L'installateur détecte Termux, utilise pkg, bundle .[termux], etc.
# ⚠️ La compilation Rust prend 20-40 min — c'est normal (voir référence dédiée)
```

**Alternative manuelle (si l'one-liner échoue) :**

```bash
pkg install -y git python clang rust make pkg-config libffi openssl nodejs ripgrep ffmpeg
git clone https://github.com/NousResearch/hermes-agent.git
cd hermes-agent
python -m venv venv
source venv/bin/activate
export ANDROID_API_LEVEL="$(getprop ro.build.version.sdk)"
pip install --upgrade pip setuptools wheel
pip install -e '.[termux]' -c constraints-termux.txt
ln -sf "$PWD/venv/bin/hermes" "$PREFIX/bin/hermes"
```

### Temps de compilation (attention !)

L'installation sur Termux est **beaucoup plus longue** que sur PC parce que
plusieurs packages doivent être **compilés depuis le code source** sur un
processeur ARM mobile. Il n'existe pas de wheels pré-compilées pour
Android/Termux.

**Durée estimée sur un SoC Helio G99 (octa-core ARM) : 20 à 40 minutes**

Ordre de compilation des packages les plus lourds :

| Package | Langage | Durée estimée | Notes |
|---------|---------|---------------|-------|
| `jiter` | Rust | 8-12 min | Le plus long — parsing JSON |
| `pydantic-core` | Rust | 5-8 min | Validation de données |
| `uvloop` | Cython | 3-5 min | Boucle d'événements |
| `watchfiles` | Rust | 3-5 min | Surveillance fichiers |
| `orjson` | Rust | 2-4 min | JSON rapide |
| `regex` | C | 1-2 min | Expressions régulières |

**Recommandations pendant la compilation :**
- ⚡ Garder le téléphone **branché** — la compilation sollicite tous les cœurs
  et vide la batterie rapidement
- 🔒 Empêcher la mise en veille de l'écran (ou désactiver l'optimisation
  batterie pour Termux) — si Android met Termux en veille pendant la
  compilation, tout plante
- ☕ C'est normal que ça prenne du temps — l'installateur n'est pas bloqué,
  il compile. Vérifie que des lignes défilent régulièrement
- Une fois l'installation terminée, tout est compilé et les lancements
  suivants sont instantanés

### Garder Termux en vie (critique)

Android tue les applis en arrière-plan. Mesures obligatoires :

1. **Wake lock** — empêche le CPU de s'endormir :
   ```bash
   pkg install termux-api
   termux-wake-lock
   ```

2. **Désactiver l'optimisation batterie** pour Termux :
   Paramètres → Applications → Termux → Optimisation batterie → **Ne pas optimiser**

3. **Verrouiller dans le récents** — sur certains téléphones, icône de verrouillage
   sur la carte Termux dans la vue des applis récentes

4. **Alimentation** — garder le téléphone branché si possible (le wake-lock
   consomme ~20-30% de batterie par jour)

### Limites connues sur Termux (d'après la doc officielle Hermes)

| Fonctionnalité | Statut |
|----------------|--------|
| CLI Hermes | ✅ Supporté |
| Cron | ✅ Supporté |
| PTY / terminal background | ✅ Supporté |
| Gateway Telegram | ✅ Supporté (best-effort) |
| Gateway WhatsApp | ✅ Fonctionne (config manuelle) |
| MCP | ✅ Supporté |
| Voice (TTS/STT) | ❌ (ctranslate2 pas de wheels Android) |
| Browser automation | ❌ (Playwright skip) |
| Docker backend | ❌ |
| `.[all]` bundle | ❌ — utiliser `.[termux]` |

### Redémarrage du téléphone

Après un redémarrage, relancer manuellement :
```bash
termux-wake-lock
source ~/.bashrc
hermes gateway start
```

Pour automatiser : utiliser **Termux:Boot** (F-Droid) avec un script
`~/.termux/boot/hermes-start.sh`.

## Oracle Cloud Free Tier (plan B gratuit)

### Ressources Always Free
- **VM ARM Ampere A1** : jusqu'à 4 CPU / 24 GB RAM / 200 GB storage
- **VM AMD Micro** : 1/8 OCPU / 1 GB RAM
- **Bande passante** : 10 TB/mois sortant

### Piège principal : disponibilité
Les instances ARM Ampere sont très demandées. Techniques pour obtenir une :
- Essayer plusieurs régions (São Paulo, Mumbai, Marseille sont moins saturées)
- Rafraîchir à différents moments de la journée
- Changer d'« availability domain »
- Passer en compte Pay-As-You-Go (carte bleue) pour avoir plus de chances

### Autres risques
- Carte de crédit obligatoire pour créer le compte
- Support client quasi inexistant pour le free tier
- Terminaison de compte possible si inactif (mais Hermes utilisé = actif)

## GitHub Student Developer Pack (plan C)

L'étudiant doit vérifier son éligibilité via `education.github.com`.

### Offres utiles pour l'hébergement

| Partenaire | Offre | Durée |
|------------|-------|-------|
| **Azure** | $100 de crédit + 25+ services gratuits | Jusqu'à épuisement |
| **DigitalOcean** | $200 de crédit | **Expire le 31 juillet 2026** |
| **GitHub Pro / Codespaces** | Gratuit pour étudiants | Pas adapté (s'éteint après 30 min d'inactivité) |

### Azure VM recommandée
Une VM B1s (1 vCPU, 1 GB RAM) coûte ~$6-8/mois → $100 de crédit = ~12-15 mois.
Configurer Hermes normalement dessus (même installation que Linux).

## Procédure de migration PC → toujours-en-ligne

**Règle d'or : un seul gateway WhatsApp actif à la fois.**
Si le PC et le téléphone tournent en même temps, tous deux répondent aux
messages → doublons et conflits. Arrêter le gateway sur l'ancienne plateforme
AVANT d'en démarrer un sur la nouvelle.

```bash
# PC : arrêter le gateway
hermes gateway stop

# Téléphone/VPS : lancer le nouveau gateway
hermes gateway start
```

Quelle que soit l'option choisie, transférer :

```bash
# 1. Installer Hermes sur la cible (Termux, VPS, Oracle...)
# 2. Copier la configuration (API keys, credentials WhatsApp)
scp -r ~/.hermes/.env user@cible:~/.hermes/
scp -r ~/.hermes/config.yaml user@cible:~/.hermes/
scp -r ~/.hermes/auth.json user@cible:~/.hermes/
scp -r ~/.hermes/gateway.json user@cible:~/.hermes/
scp -r ~/.hermes/skills user@cible:~/.hermes/

# 3. Configurer le provider
hermes model

# 4. Configurer le gateway
hermes gateway setup   # → scanner le QR code
# Si tu es sur le même appareil que Termux (impossible de scanner la caméra) :
#   → faire une capture d'écran du QR code
#   → WhatsApp → Paramètres → Appareils liés → Lier un appareil
#   → appuyer sur l'icône galerie pour sélectionner la capture d'écran
hermes gateway start

# 5. Vérifier
hermes gateway status
hermes doctor
```

## Pitfalls

- **Termux depuis Google Play** — toujours utiliser F-Droid ou GitHub Releases
- **Compilation Rust interminable** — c'est normal, prévoir 20-40 min sur un
  Helio G99 (ou plus sur un SoC plus faible). Prévenir l'étudiant AVANT
  de lancer l'installation pour qu'il ne pense pas à un plantage
- **Téléphone qui s'éteint pendant la compilation** — brancher et désactiver
  la mise en veille avant de lancer l'installateur. Si la compilation est
  interrompue, reprendre avec `pip install -e '.[termux]' -c constraints-termux.txt`
- **ANDROID_API_LEVEL non défini** — `jiter`/`maturin` échouent sans ça. Vérifier
  avec `echo $ANDROID_API_LEVEL` avant d'installer manuellement
- **Doublon de cron** — après migration, supprimer les anciens crons sur le PC
- **Temps de réponse** — le téléphone en 4G peut avoir une latence plus élevée
  qu'un VPS en fibre — acceptable pour WhatsApp mais visible
- **Batterie** — prévoir de laisser le téléphone branché la nuit
