---
name: linux-audio-diagnostics
description: "Diagnostiquer les problèmes audio sous Linux (PipeWire/WirePlumber/SOF) — workflow systématique en entonnoir : noyau → PipeWire → WirePlumber → UCM → applications."
---

# Linux Audio Diagnostics

Utiliser ce workflow quand un utilisateur signale que le son ne fonctionne plus (pas de son, périphérique manquant, sink manquant).

## Triggers

- "le son ne marche plus" / "plus de son" / "haut-parleur muet"
- "Dummy Output" comme seul sink disponible dans les paramètres son
- ALSA device détecté mais pas de sink PipeWire
- Son qui fonctionnait avant mais plus après une mise à jour/redémarrage

## Workflow de diagnostic (entonnoir 6 couches)

**Réflexe n°1 avant toute investigation** — Un restart résout ~80% des cas SOF HDA :
```bash
systemctl --user restart pipewire.service wireplumber.service
sleep 2
wpctl status
```

### Couche 1 — Services audio : tournent-ils ?

### Couche 1 — Services audio : tournent-ils ?

```bash
# Vérifier que PipeWire et WirePlumber tournent
systemctl --user status pipewire.service pipewire-pulse.service wireplumber.service

# Les trois doivent être actifs (running). Si l'un est mort :
systemctl --user restart pipewire.service wireplumber.service
```

Si redémarrer corrige le problème → **état interne corrompu de WirePlumber** (connu sur SOF HDA après mise en veille ou changement de profil). Le fix est le redémarrage, pas d'autre investigation nécessaire.

**Piège :** `pactl info` peut échouer avec "Connection refused" même si PipeWire tourne. Utiliser `systemctl --user status pipewire.service` ou `pw-cli info all` à la place.

### Couche 2 — Sinks disponibles

```bash
# Voir tous les sinks (sorties audio)
wpctl status

# Voir les nodes ALSA dans PipeWire
pw-cli list-objects Node | grep -E "node.name|node.description|media.class"
```

**Interprétation :**
- Plusieurs sinks (Speaker, HDMI, Headphones) ✅ → tout va bien, vérifier plutôt l'application
- **Un seul sink "Dummy Output"** → WirePlumber n'a pas créé de sinks depuis l'ALSA → **Couche 3**
- Aucun sink du tout → PipeWire ne tourne pas → **Couche 1**

### Couche 3 — Carte ALSA détectée par WirePlumber

```bash
# Lister les devices ALSA
pw-cli list-objects Device | grep -E "device.name|device.description|media.class|device.api"

# Détails du device (remplacer ID par celui du device ALSA)
pw-cli info <ID>
```

Regarder les propriétés :
- `device.api = "alsa"` ✅ → WirePlumber voit la carte
- `api.acp.auto-profile = false` et `api.acp.auto-port = false` → comportement normal (désactivé par défaut)
- `api.alsa.use-acp = true` ✅

**Tags de l'infolettre** : si la carte est SOF HDA (`sof-hda-dsp`, `skl_hda_dsp_generic`), c'est un cas connu.

Si le device n'apparaît PAS du tout → **problème noyau/driver** :

```bash
# Vérifier la détection ALSA
aplay -l
cat /proc/asound/cards
cat /proc/asound/card0/codec#0 | head -20

# Tester l'accès direct au matériel
speaker-test -l1 -D hw:0,0 -c2 -t sine
# Écouter : un bruit rose doit sortir des haut-parleurs
```

### Couche 4 — UCM (Use Case Manager) et contrôles ALSA

Les profils de périphériques sont définis par UCM. Si UCM ne trouve pas de section qui match, aucun sink n'est créé.

```bash
# Voir les contrôles ALSA disponibles
amixer controls

# Vérifier si les contrôles attendus par UCM existent
# Pour HDA analogique, UCM attend :
#   'Master Playback Switch' → doit exister
#   'Speaker Playback Switch' → optionnel
#   'Headphone Playback Switch' → optionnel

# Voir la config UCM HDA
cat /usr/share/alsa/ucm2/HDA/HiFi-analog.conf
```

**Problème connu (HP EliteBook 830 G6 avec SOF HDA) :**
Le driver SOF expose seulement `Master Playback Switch`/`Volume`, PAS les contrôles individuels `Speaker Playback Switch` ou `Headphone Playback Switch`. La section `If.spk` dans `HiFi-analog.conf` échoue silencieusement → aucun sink Speaker créé.

**Vérification rapide :**
```bash
# Si 'Speaker Playback Switch' n'existe pas MAIS 'Master Playback Switch' oui,
# c'est le bug UCM → redémarrer WirePlumber résout parfois
systemctl --user restart pipewire.service wireplumber.service
sleep 2
wpctl status
```

### Couche 5 — WirePlumber rules / configuration override

Si le redémarrage ne suffit pas, forcer ACP auto-profile dans WirePlumber :

```bash
# Créer un override de configuration
mkdir -p ~/.config/wireplumber/wireplumber.conf.d
cat > ~/.config/wireplumber/wireplumber.conf.d/51-hp-elitebook-audio.conf << 'CONF'
monitor.alsa.rules = [
  {
    matches = [
      {
        device.name = "~alsa_card.*skl_hda_dsp*"
      }
    ]
    actions = {
      update-props = {
        api.acp.auto-profile = true
        api.acp.auto-port = true
      }
    }
  }
]
CONF

systemctl --user restart pipewire.service wireplumber.service
```

**⚠️ Note :** Les `monitor.alsa.rules` opèrent sur les **nodes** (PCM), pas directement sur les **devices**. Si l'UCM ne crée aucun node, cette approche peut ne pas suffire. Préférer d'abord le redémarrage simple (Couche 1).

### Couche 6 — Changements récents système

```bash
# Historique apt récent
tail -30 /var/log/apt/history.log

# Rechercher les mises à jour sensibles
grep -E "install|upgrade" /var/log/dpkg.log | grep -E "pipewire|wireplumber|sof|alsa|kernel" | tail -20
```

## Solutions rapides

| Symptôme | Diagnostic | Solution |
|----------|-----------|----------|
| "Dummy Output" seul sink | WirePlumber n'a pas créé de sinks ALSA | `systemctl --user restart pipewire.service wireplumber.service` |
| ALSA device détecté, pas de Speaker | UCM ne match pas (contrôle manquant) | Voir Couche 4 — redémarrer les services |
| ALSA direct (`speaker-test`) OK, pas de son dans les apps | PipeWire routing cassé | `wpctl set-default <sink_id>` |
| Son qui fonctionnait avant, plus après veille | État WirePlumber corrompu | Redémarrer WirePlumber (`systemctl --user restart`) |
| Pas de son sur HDMI | HDMI non activé dans UCM | Vérifier `pw-cli info` sur les HDMI sinks |

## Pièges à éviter

- **Penser que `pactl` fonctionne** : `pactl info` échoue si PipeWire-Pulse n'est pas le fournisseur PulseAudio. Utiliser `pw-cli` et `wpctl` à la place.
- **Modifier la config WirePlumber system-wide** : Les fichiers dans `/usr/share/wireplumber/` sont écrasés à chaque mise à jour. Utiliser `~/.config/wireplumber/` pour les overrides utilisateur.
- **Oublier le `sleep 2` après restart** : PipeWire/WirePlumber mettent ~1-2s à scanner le matériel ALSA. Vérifier trop tôt montre encore le Dummy Output.
- **Confondre driver HDA classique et SOF** : `snd-hda-intel` (classique) et `sof-hda-dsp` (SOF) exposent des contrôles ALSA différents. L'UCM attend des contrôles que SOF ne fournit pas forcément.
- **Amixer ne montre que Master** : Sur SOF HDA, `amixer` ne montre que les contrôles principaux. C'est normal — les réglages fins (Speaker, Headphone) sont gérés par le firmware, pas accessibles via ALSA.

## Commandes de référence

```bash
# État général
wpctl status
pw-cli list-objects Node | grep -E "node.name|node.description|media.class"

# Détails ALSA
aplay -l
cat /proc/asound/cards
amixer controls

# Test ALSA direct
speaker-test -l1 -D hw:0,0 -c2 -t sine

# Détails device PipeWire
pw-cli info $(pw-cli list-objects Device | grep -B1 "alsa" | grep id | head -1 | grep -oP '\d+')

# Logs WirePlumber
journalctl --user -u wireplumber.service --no-pager -n 30

# Restart complet
systemctl --user restart pipewire.service wireplumber.service

# Forcer le sink par défaut
wpctl set-default <sink_id>
```
