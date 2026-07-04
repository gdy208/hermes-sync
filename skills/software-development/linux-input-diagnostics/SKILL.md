---
name: linux-input-diagnostics
description: "Diagnostiquer les problèmes de périphériques d'entrée (souris, clavier, pavé tactile) sous Linux X11/Wayland — workflow systématique en entonnoir : noyau → libinput → display server."
---

# Linux Input Diagnostics

Utiliser ce workflow quand un utilisateur signale des clics, tapotements, ou mouvements qui ne fonctionnent pas.

## Trigger

- "clic gauche ne marche pas" / "souris hs" / "pavé tactile mort" / "boutons ne répondent plus"
- Problème avec TOUS les périphériques (souris USB + pavé tactile + souris PS/2) = logiciel, pas matériel
- Problème avec UN SEUL périphérique = peut être matériel (microswitch usé)

## Workflow de diagnostic (entonnoir 4 couches)

### Couche 1 — Noyau : détection + événements bruts

```bash
# Détection matérielle
cat /proc/bus/input/devices
ls /dev/input/by-id/
xinput list                         # XWayland seulement
```

Si le périphérique n'est pas listé → problème noyau/USB/BIOS (driver manquant, débrancher/rebrancher).

```bash
# Installer evtest
sudo apt-get install -y evtest

# Capturer les événements bruts (remplacer eventX)
sudo timeout 8 evtest /dev/input/eventX
```

Ne PAS utiliser `--grab` dans un test initial — il bloque les autres applications.

**Interprétation des résultats evtest :**
- `BTN_LEFT value 1` / `BTN_RIGHT value 1` présents → le clic arrive au noyau ✅ → **problème dans les couches supérieures**
- Mouvement (`REL_X`/`REL_Y`) et molette (`REL_WHEEL`) OK, mais `BTN_*` jamais émis → **microswitch mort** si 1 souris, ou **problème noyau/HID** si tous les périphériques
- Rien du tout → **périphérique non détecté** (vérifier `dmesg`, `lsusb`, débrancher/rebrancher)

### Couche 2 — libinput : abstraction HID

```bash
# Lister les devices vus par libinput
sudo libinput list-devices

# Capturer les événements
sudo libinput debug-events --device /dev/input/eventX
```

**Interprétation :**
- `POINTER_BUTTON BTN_LEFT pressed` visible → libinput reçoit les clics ✅ → **problème dans le display server**
- Rien alors qu'evtest montrait des événements → **bug dans libinput** ou **mauvaise configuration**

### Couche 3 — Display server

**Wayland (GNOME/Mutter) :**
```bash
# Paramètres d'accessibilité (Sticky Keys, Slow Keys, etc.)
gsettings list-recursively org.gnome.desktop.a11y

# Paramètres périphériques
gsettings list-recursively org.gnome.desktop.peripherals.mouse
gsettings list-recursively org.gnome.desktop.peripherals.touchpad
dconf dump /org/gnome/desktop/peripherals/

# Features expérimentales mutter
gsettings get org.gnome.mutter experimental-features
# → xwayland-native-scaling est connu pour causer des bugs d'entrée

# Mode de focus
gsettings get org.gnome.desktop.wm.preferences focus-mode

# Logs gnome-shell
journalctl --user -u gnome-shell* --no-pager -n 50

# Redémarrer le shell sans logout
busctl call org.gnome.Shell /org/gnome/Shell org.gnome.Shell Eval s 'Meta.restart("Restarting...")'
```

**X11 :**
```bash
xinput list-props <ID>
grep -i "mouse\|touchpad\|input" /var/log/Xorg.0.log | head -20
```

### Couche 4 — Changements récents système

```bash
# Historique apt récent
tail -30 /var/log/apt/history.log

# Rechercher les mises à jour sensibles
grep -E "install|upgrade" /var/log/dpkg.log | grep -E "xserver|xorg|mutter|gnome-shell|libinput|kernel" | tail -20

# Erreurs du noyau récentes
journalctl -k --no-pager -n 50 | grep -i "error\|fail\|usb\|input"
```

Un redémarrage complet de la machine réserve parfois des surprises.

## Solutions rapides (une fois le diagnostic posé)

| Diagnostic | Solution |
|---|---|
| Couche 1+2 OK, 3 bloqué (Wayland) | Redémarrer GNOME Shell : `busctl call org.gnome.Shell...` ou déconnexion/reconnexion |
| `xwayland-native-scaling` activé | `gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']"` puis redémarrer |
| Paramètre `left-handed` inversé par erreur | `gsettings set org.gnome.desktop.peripherals.mouse left-handed false` |
| 1 souris seule en défaut, toutes les couches OK | Remplacer la souris OU nettoyer le microswitch (souffler + cliquer 50x à vide) |
| Mise à jour `xserver-xorg-core` récente | Déconnexion/reconnexion complète (pas juste un redémarrage shell) |
| Aucune piste trouvée | Repasser en X11 depuis l'écran de connexion (GNOME → Xorg) pour isoler Wayland vs X11 |

## Pièges à éviter

- **xinput sans comprendre Wayland** : `xinput list` ne montre QUE les périphériques XWayland. Sur Wayland, les vrais périphériques peuvent ne pas y apparaître. Utiliser `/proc/bus/input/devices` ou `libinput list-devices` pour la vue complète.
- **--grab accidentel** : Capturer avec `--grab` empêche les événements d'atteindre les applications. C'est utile pour un test isolé mais ne PAS oublier de le relâcher.
- **Permission /dev/input/eventX** : L'utilisateur doit être dans le groupe `input` ou utiliser `sudo`. Vérifier avec `groups`, ajouter avec `sudo usermod -a -G input $USER` (déconnexion/reconnexion nécessaire).
- **Ne pas généraliser un test** : Tester avec la souris USB uniquement, puis avec le pavé tactile uniquement. Si les deux sont en défaut → logiciel. Si un seul → matériel.
- **Rien dans evtest alors que user clique** : Vérifier que le bon périphérique est testé. `cat /proc/bus/input/devices` pour trouver les eventX exacts.
- **Wayland = pas de Alt+F2,r** : La commande classique de redémarrage du shell ne fonctionne PAS sur Wayland. Utiliser `busctl call org.gnome.Shell...` ou simplement se déconnecter.

## Références

- evtest manpage (`man evtest`)
- libinput documentation (`man libinput`)
- `/proc/bus/input/devices` — tous les périphériques d'entrée connus du noyau
- `/var/log/apt/history.log` — historique des modifications de paquets
