---
name: cisco-packet-tracer
description: "Tutorat interactif sur Cisco Packet Tracer — réseau, masques, switch, routeur, VLAN, NAT/DMZ. Progression 6 labs."
version: 1.0.0
author: agent
platforms: [linux]
metadata:
  hermes:
    tags: [cisco, packet-tracer, reseau, formation, lab, tutoring]
---

# Cisco Packet Tracer — Tutorat Réseau

Skill de tutorat pour la formation réseau sur Cisco Packet Tracer (6 labs progressifs). S'adresse à Gédéon, étudiant INPHB/ESI, objectif DevOps/IA. Cette skill est partagée entre les deux instances Hermes via GitHub (`hermes-config/skills/education/cisco-packet-tracer/`).

## Progression des 6 Labs

1. **Ping entre deux PCs** — communication directe, câble cross-over, IP/masque 
2. **Switch** — interconnecter 4+ PCs, CAM table, domaine de collision vs diffusion, CDP/DTP, ARP
3. **Routeur** — connecter deux sous-réseaux, gateway, table de routage
4. **VLAN** — segmentation logique, trunk, 802.1Q
5. **Routage inter-VLAN** — routeur-on-a-stick, sous-interfaces
6. **NAT et DMZ** — accès internet, PAT, zone démilitarisée

Chaque lab est détaillé plus bas dans la section #Labs détaillés.

## Méthode pédagogique

1. **Concept** — analogie du monde réel (maison/quartier, téléphone, rue)
2. **Binaire** — montrer le pattern en binaire (le moment "ah !")
3. **Manipulation** — l'utilisateur reproduit dans Packet Tracer
4. **Test** — ping, observation des résultats (vert/rouge, timeout)
5. **Validation** — question piège pour vérifier la compréhension profonde

## Règles d'explication

### Terminologie (IMPORTANT)
- Toujours utiliser **"octets"** (pas "chiffres") pour les 4 parties d'une IP
- Dire "4e octet", pas "4e chiffre"
- Dire "sous-réseau", pas "sous-ensemble"
- Le masque sont des octets, pas des nombres

### Masque réseau
- Expliquer d'abord en décimal (`255.255.255.0`)
- Puis basculer en binaire pour le "déclic"
- Montrer le calcul AND (IP & Masque = réseau)
- Distinguer `/24`, `/25`, `/26`... `/30`
- Insister : le masque est **propre à chaque interface** — deux machines avec des masques différents ne sont pas d'accord sur les limites du réseau

### Câbles
- **Straight-Through** : PC ↔ Switch, Switch ↔ Routeur (équipements différents)
- **Cross-Over** : PC ↔ PC, Switch ↔ Switch (équipements identiques)

### Voyants
- **Vert/Orange** = lien actif
- **Rouge** = pas de lien (mauvais câble, port éteint)
- **Ambre clignotant** = activité

## Pièges à éviter

- ❌ Ne pas utiliser "chiffres" pour les octets — l'utilisateur a corrigé cette confusion
- ❌ Ne pas sauter l'explication binaire — c'est ce qui fait comprendre le masque
- ❌ Ne pas expliquer le routeur avant que le switch soit maîtrisé
- ❌ Ne pas donner la réponse aux questions pièges tout de suite — laisser l'utilisateur tester dans Packet Tracer
- ❌ Ne pas sous-estimer la confusion entre "réseau" et "sous-réseau"
- ✅ Toujours valider avec un test pratique (ping, changement d'IP, changement de masque)

## Labs détaillés

### Lab 1 — Ping entre deux PCs
- Câble **Cross-Over** entre deux PCs (équipements identiques)
- Objectif : vérifier la compréhension IP/masque
- Question piège : changer le masque d'un PC et observer si le ping passe encore

### Lab 2 — Switch (interconnecter 4+ PCs)

**Montage :** 1 Switch 2960 + 4 PCs en Straight-Through

**Notions clés :**
- **CAM table** (`show mac address-table`) : le switch apprend les MAC en écoutant les trames entrantes. Un PC silencieux n'apparaît pas dans la table — il faut qu'il envoie un paquet.
- **Hub vs Switch** : le hub répète tout sur tous les ports (domaine de collision unique), le switch aiguille par port (un domaine de collision par port). Avec un hub, deux PCs qui parlent en même temps provoquent une collision.
- **CDP/DTP** : le switch envoie périodiquement CDP (Cisco Discovery Protocol) et DTP (Dynamic Trunking Protocol) sur ses ports pour découvrir les voisins. C'est du bruit de fond normal.
- **ARP** : pour joindre une IP dont la MAC est inconnue, le PC envoie un ARP broadcast (FF:FF:FF:FF:FF:FF) — le switch le diffuse sur tous les ports.
- **Timeout CAM** : une MAC disparaît de la table après ~300s (5 min) d'inactivité. Débrancher un PC ne vide pas immédiatement sa CAM.

**Question piège :** changer le masque d'un PC pour voir si les hôtes sont toujours dans le même sous-réseau.

### Lab 3 — Routeur (connecter deux sous-réseaux)

**Montage :** 1 Routeur 1941, 2 switches, 4 PCs (2 par switch)

**Réseaux :** 192.168.1.0/24 (côté G0/0) et 192.168.2.0/24 (côté G0/1)

**Configuration du routeur (CLI) :**
```
enable
configure terminal
interface gigabitEthernet 0/0
 ip address 192.168.1.254 255.255.255.0
 no shutdown
 exit
interface gigabitEthernet 0/1
 ip address 192.168.2.254 255.255.255.0
 no shutdown
 exit
exit
show ip route
```

**Concept clé — Gateway :** chaque PC a sa gateway = l'IP du routeur sur son réseau. Quand un PC veut parler à une IP hors de son réseau, il envoie le paquet à sa gateway. Le routeur consulte sa table de routage (`show ip route`) et transmet sur l'interface appropriée.

**Phénomène du premier ping perdu (ARP delay) :**
Quand un PC ping pour la première fois une IP hors de son réseau :
1. Le PC doit d'abord résoudre l'ARP de sa gateway → broadcast + réponse
2. Puis le routeur doit résoudre l'ARP de la destination sur l'autre réseau
3. Pendant ces deux résolutions ARP, le premier ICMP Echo Request arrive après le timeout → "Request timed out"
4. Les pings suivants passent instantanément car les MAC sont en cache (`arp -a`)
5. Le cache ARP expire au bout de ~5 minutes — re-perdre le premier ping après une pause est normal

**Routes directement connectées :** le routeur connaît automatiquement les réseaux branchés sur ses interfaces. `show ip route` les montre comme `C` (connected).

**En mode Simulation Packet Tracer :** décocher tous les filtres sauf ICMP pour ne voir que les pings. Activer ARP dans les filtres pour voir les requêtes de résolution. Si l'utilisateur a désactivé ARP, il verra d'autres protocoles (CDP, DTP) — ne pas le corriger mais demander d'ouvrir l'onglet PDU Details pour identifier le protocole réel.

**Question piège :** changer la gateway d'un PC pour son IP personnelle (192.168.1.1 au lieu de 192.168.1.254). Le PC ne pourra plus joindre l'autre réseau car le paquet ne part pas vers le routeur.

### Lab 4 — VLAN (segmentation logique)

**Montage :** 1 Switch 2960 + 4 PCs en Straight-Through

**Réseau :** tous les PCs dans 192.168.1.0/24 (même réseau IP)

**Configuration des VLANs (CLI switch) :**
```
enable
configure terminal
vlan 10
 name COMPTA
 exit
vlan 20
 name COMMERCIAL
 exit
interface fastEthernet 0/1
 switchport mode access
 switchport access vlan 10
 exit
interface fastEthernet 0/2
 switchport mode access
 switchport access vlan 10
 exit
interface fastEthernet 0/3
 switchport mode access
 switchport access vlan 20
 exit
interface fastEthernet 0/4
 switchport mode access
 switchport access vlan 20
 exit
show vlan brief
```

**Notions clés :**
- Un **VLAN** isole le trafic au niveau **couche 2** (switch) sans changer l'IP
- Même réseau IP (192.168.1.x) mais les VLANs 10 et 20 ne peuvent pas se parler — le switch bloque les trames entre VLANs
- `show vlan brief` montre quels ports sont dans quel VLAN
- PC ne peut pas joindre un autre PC dans un VLAN différent → **timeout** au ping
- Re-brancher un PC sur un port d'un autre VLAN le fait changer de VLAN — c'est le port qui détermine le VLAN, pas la machine

**Question piège :** si on rebranche PC2 (VLAN 20) sur le port Fa0/1 (VLAN 10), est-ce que PC2 peut parler à PC0 ? (Réponse : oui, car le port détermine le VLAN.)

**Prochaine étape :** pour que les VLANs puissent communiquer, il faut un **routeur** en trunk → Lab 5 (routage inter-VLAN).

### Lab 5 — Routage inter-VLAN
- routeur-on-a-stick, sous-interfaces

### Lab 6 — NAT et DMZ
- accès internet, PAT, zone démilitarisée

## Méthode dual-track (apprentissage alterné)

Ce parcours alterne **Cisco Packet Tracer** (théorie réseau manipulée) et **projets build-your-own** (implémentation en Python). Chaque lab Cisco pose les concepts qu'un projet code juste après.

**Cycle type :** lab Cisco → l'utilisateur manipule IP/ports/TCP dans Packet Tracer → projet Python → il code un serveur qui utilise exactement ces mécanismes → question piège qui fait le pont entre les deux ("ce port sur le routeur = le port 8888 dans socket.bind()").

**Pattern pré-étude :** avant un nouveau projet (ex: première librairie `socket`), envoyer la veille un résumé des notions via Signal : cycle de vie, méthodes clés avec équivalent réseau, code complet à étudier, une question pour amorcer la réflexion.

### Planification recommandée
```
Phase 1  → Labs 1-3 Cisco  → HTTP Server
Phase 2  → Labs 4-5 Cisco  → Mini Redis
Phase 3  → Lab 6 Cisco     → Docker + Git
Phase 4  → CI System
```

## Liens avec le parcours DevOps

Chaque lab Cisco prépare un projet build-your-own :
- Lab 2 (Switch) + Lab 3 (Routeur) → HTTP Server (sockets, TCP, ports)
- Lab 4-5 (VLAN) → Mini Redis (protocole, connexions multiples)
- Lab 6 (NAT) → Docker (isolation réseau)

Voir `references/build-your-own-devops.md` pour les liens lab → projet détaillés.
Voir `Courses/Formation-DevOps-IA.md` dans le vault pour le plan complet.

## Commandes Packet Tracer utiles

```
ping <IP>              # Test de connectivité
ipconfig               # Voir l'IP/masque/gateway (Desktop → Command Prompt)
show running-config    # Config actuelle d'un équipement (CLI)
show ip route          # Table de routage (routeur)
show vlan brief        # VLANs configurés (switch)
show mac address-table # Table d'apprentissage du switch (CAM)
```

## Pièges à éviter (suite)

- ❌ Ne pas corriger l'utilisateur sur le protocole qu'il voit — il peut avoir filtré certains protocoles dans la simulation. Vérifier d'abord en lui demandant l'onglet PDU Details.
- ❌ Ne pas expliquer le routeur avant que le switch soit maîtrisé — le concept de gateway suppose compris ce qu'est un sous-réseau.
- ❌ Ne pas sous-estimer la confusion réseau vs sous-réseau.
- ✅ Toujours valider avec un test pratique (ping, changement d'IP, changement de masque).
- ✅ Laisser l'utilisateur tester lui-même les scénarios dans Packet Tracer avant de donner la réponse.

## Références

- Les 6 labs sont documentés dans `~/obsidian-vault/Labs/Cisco/`
- Progression intégrée à la Semaine 6 de la formation DevOps/IA
- Parcours build-your-own associé : `references/build-your-own-devops.md` (repo, structure, liens lab → projet)