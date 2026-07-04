# Quick Diagnostic Commands

Checklist reproductible pour diagnostiquer un problème d'entrée Linux.

```bash
# 1. Matériel détecté ?
cat /proc/bus/input/devices | grep -E "Name=|Handlers="
ls /dev/input/by-id/ | grep -i mouse

# 2. Événements bruts noyau
sudo timeout 6 evtest /dev/input/eventX | grep BTN
# Remplacer eventX par le handler du device (ex: event17)

# 3. Couche libinput
sudo libinput list-devices
sudo timeout 6 libinput debug-events --device /dev/input/eventX

# 4. Display server (Wayland)
gsettings get org.gnome.mutter experimental-features
gsettings list-recursively org.gnome.desktop.peripherals.mouse
gsettings list-recursively org.gnome.desktop.a11y
dconf dump /org/gnome/desktop/peripherals/

# 5. Historique récent
tail -20 /var/log/apt/history.log
grep -E "install|upgrade" /var/log/dpkg.log | grep -E "xserver|mutter|gnome-shell|libinput" | tail -10

# 6. Redémarrage du shell Wayland
busctl call org.gnome.Shell /org/gnome/Shell org.gnome.Shell Eval s 'Meta.restart("Restarting...")'
```
