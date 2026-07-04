---
name: lan-file-transfer
title: LAN File Transfer
description: Transférer des fichiers entre appareils sur le même réseau local. Serveur HTTP, netcat, SCP, selon l'OS cible.
domain: productivity
tags:
  - network
  - file-transfer
  - http-server
  - python
  - linux
---

# LAN File Transfer

Transférer un fichier (ou plusieurs) depuis un PC Linux vers un autre appareil
(téléphone, tablette, autre PC) sur le même réseau local.

## Quand utiliser ce skill

- L'utilisateur demande comment envoyer un fichier sur son téléphone / l'autre PC
- Pas de clé USB, pas de cloud, pas de câble
- Les deux appareils sont sur le même réseau (Wi-Fi ou ethernet)

## Méthode 1 — Serveur HTTP Python (recommandée, tout OS cible)

> Cible : téléphone (Android/iOS via navigateur), tablette, tout appareil avec un browser.

### Procédure

1. **Localiser le(s) fichier(s)** à partager

2. **Trouver l'IP locale** de la machine serveuse :
   ```
   hostname -I
   ```
   ou
   ```
   ip -4 addr show | grep -v 127.0.0.1
   ```

3. **Vérifier qu'aucun port n'est déjà occupé** (piège courant : Docker) :
   ```
   sudo ss -tlnp | grep 8080
   ```
   Si occupé, prendre un autre port (8081, 9999, etc.)

4. **Lancer le serveur** en bindant **0.0.0.0** (indispensable pour le réseau local) :
   ```
   cd ~/Documents && python3 -m http.server 8080 --bind 0.0.0.0
   ```

5. **Côté client** (téléphone) : navigateur vers `http://<IP_DU_SERVEUR>:8080`

6. **Arrêter** : Ctrl+C dans le terminal

### Pièges fréquents

- **Binding par défaut sur 127.0.0.1** — si un autre processus occupe déjà 0.0.0.0 ou si le port est déjà lié, Python peut se rabattre sur localhost. **Toujours** specifier `--bind 0.0.0.0`.
- **Port déjà utilisé** — `docker-proxy`, autres services. Verifier avec `sudo ss -tlnp | grep <port>` avant de lancer.
- **Firewall** — `ufw` peut bloquer. Verifier avec `sudo ufw status`.
- **Connexion refusée** — verifier que le port écoute sur `0.0.0.0` et pas `127.0.0.1`.

## Méthode 2 — Netcat (un seul fichier, cible Linux/Android-Termux)

### Cote récepteur (d'abord) :
```
nc -l -p 9999 > fichier_recu.pdf
```

### Cote émetteur (ensuite) :
```
nc -w 3 <IP_RECEPTEUR> 9999 < fichier_a_envoyer.pdf
```

### Piège
- L'ordre est important : le récepteur écoute avant que l'émetteur envoie.
- `-w 3` ferme la connexion apres 3s d'inactivite.

## Méthode 3 — SCP (Linux vers Linux, SSH)

```
scp ~/Documents/mon_fichier.pdf user@<IP_DEST>:/home/user/
```

Nécessite SSH serveur côté destinataire.

## Diagnostic réseau

- **Voir les IP locales** : `ip -4 addr show | grep -v 127.0.0.1`
- **Voir ce qui écoute sur un port** : `sudo ss -tlnp | grep <port>`
- **Libérer un port** : `fuser -k <port>/tcp` ou `sudo kill <PID>`
- **Vérifier le firewall** : `sudo ufw status`

## Dépendances

- Python3 (methode 1) — préinstallé
- netcat-openbsd (`nc`, methode 2) — `sudo apt install netcat-openbsd`
- openssh-client (methode 3) — généralement préinstallé
