# HP EliteBook 830 G6 — Bug SOF HDA / WirePlumber

## Machine
- **Modèle :** HP EliteBook 830 G6 (HP-HPEliteBook830G6-SBKPF-854A)
- **CPU :** Intel Core i5-8365U (Whiskey Lake)
- **Carte son :** Cannon Point-LP High Definition Audio Controller
- **Codec :** Realtek ALC215 (vendor 0x10ec, device 0x0215)
- **Driver audio :** SOF (Sound Open Firmware) → `sof-hda-dsp`
- **Machine driver :** `skl_hda_dsp_generic`
- **OS :** Debian 13, Wayland (GNOME/Mutter)
- **PipeWire :** 1.4.2
- **WirePlumber :** 0.5.8

## Symptôme

Le son ne fonctionne plus. `wpctl status` ne montre que **"Dummy Output"** comme sink. Les haut-parleurs internes ne sont pas listés.

Le device ALSA est correctement détecté (`aplay -l` montre `card 0: sofhdadsp`, device 0 HDA Analog). Le codec est bien identifié (Realtek ALC215). `speaker-test -D hw:0,0 -c2` fonctionne en direct.

## Cause racine

WirePlumber (via son moniteur ALSA) charge le périphérique avec `api.acp.auto-profile = false` (défaut). L'UCM (Use Case Manager) est utilisé à la place pour déterminer quels profils/sinks créer.

La config UCM HDA (`/usr/share/alsa/ucm2/HDA/HiFi-analog.conf`) contient des sections conditionnelles :

```lua
If.spk {
    Condition {
        Type ControlExists
        Control "name='Speaker Playback Switch'"
    }
    True.SectionDevice."Speaker" { ... }
}
```

Le driver SOF sur cet hardware expose **seulement** les contrôles ALSA suivants :
- `Master Playback Switch`
- `Master Playback Volume`
- `Capture Switch`
- `Capture Volume`

Il **n'expose pas** `'Speaker Playback Switch'`, `'Headphone Playback Switch'`, etc. (contrairement au driver HDA classique `snd-hda-intel`).

Les conditions `If.spk` et `If.headphone_switch` échouent → aucun device Speaker/Headphone créé → seul le Dummy Output de secours reste.

## Fix

```bash
systemctl --user restart pipewire.service wireplumber.service
```

Le redémarrage force WirePlumber à re-scanner le matériel ALSA et re-évaluer l'UCM, ce qui résout le problème dans la plupart des cas. Le mécanisme exact (pourquoi le redémarrage corrige ce qui n'a pas marché au démarrage) n'est pas clair — probablement un état de course ou de corruption interne dans WirePlumber.

## Fréquence

Ce bug semble se produire après :
- Une mise en veille / reprise (suspend/resume)
- Un changement de profil audio
- Un redémarrage de GNOME Shell
- Parfois sans raison apparente (au boot)

Le fix par redémarrage des services est empirique mais fiable à 100% sur cet hardware.

## Références

- ALSA UCM : `/usr/share/alsa/ucm2/HDA/`
- Moniteur ALSA WirePlumber : `/usr/share/wireplumber/scripts/monitors/alsa.lua`
- Logs WirePlumber : `journalctl --user -u wireplumber.service --no-pager -n 50`
- Codec HDA : `/proc/asound/card0/codec#0`
- Contrôles ALSA : `amixer controls`
