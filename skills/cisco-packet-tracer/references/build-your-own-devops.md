# Build Your Own DevOps — Parcours intégré

Repo GitHub : `github.com/gdy208/build-your-own-devops`

## Structure

5 projets progressifs en Python, pensés pour un étudiant DevOps S5 avec bases Cisco :

```
build-your-own-devops/
├── 01-http-server/   → Serveur HTTP from scratch (rspivak/lsbaws)
├── 02-mini-redis/    → Redis-like en Python (coleifer/simpledb)
├── 03-docker/        → Conteneurs Linux en Python (tonybaloney/mocker)
├── 04-git/           → Git from scratch (thblt/write-yourself-a-git)
└── 05-ci-system/     → CI system (aosabook/500lines)
```

## Liens avec Cisco Packet Tracer

| Lab Cisco | Notion | Projet build-your-own |
|-----------|--------|----------------------|
| Lab 2 (Switch) | Broadcast, MAC, trame | HTTP Server (socket.recv envoye sur un port) |
| Lab 3 (Routeur) | Gateway, table de routage | HTTP Server (bind/accept = ouvrir un port et attendre) |
| Lab 4-5 (VLAN/Inter-VLAN) | Isolation, trunk, sous-interfaces | Mini Redis (connexions multiples isolees) |
| Lab 6 (NAT/DMZ) | Traduction d'adresse, PAT | Docker (network namespaces, bridge) |

## Ordre recommandé d'attaque

1. Labs Cisco 1-3 → HTTP Server (les sockets font echo au TCP manipule)
2. Labs Cisco 4-5 → Mini Redis (protocole RESP, commandes, multi-clients)
3. Lab Cisco 6 → Docker (isolation reseau)
4. Git (independant, peut etre fait a tout moment apres HTTP Server)
5. CI System (projet chapeau qui boucle tout)

## Notes sur le repo

- Chaque projet est du code pret a etudier et modifier, pas un tutoriel vide
- Le dossier 05-ci-system (500 Lines) contient bien plus que le CI : web-server, data-store, template-engine, cluster — bonus exploitables
- Tous les .git originaux ont ete supprimes pour faire place a un seul git parent
- Repo prive sur gdy208/build-your-own-devops
