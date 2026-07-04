# Prompt d'audit complet Hermes

Prompt auto-suffisant à coller dans Hermes pour lancer un audit : skills, hub, sync GitHub, config, plan d'action priorisé.

## Usage

```bash
/moa <coller le prompt>
```

ou en session normale, coller tel quel.

## Prompt

```
🎯 Mission : audit complet et optimisation de cette instance Hermes.

Tu utilises le preset MoA "performance" (Flash + Qwen3.7 Max) pour la qualité maximale.
Si MoA n'est pas disponible, utilise juste le modèle par défaut.

Tu travailles en français.

#

Objectifs :
1. Auditer l'état des skills installés
2. Suggérer des améliorations concrètes
3. Chercher des skills complémentaires dans le hub
4. Auditer la stratégie de sauvegarde / synchronisation GitHub
5. Produire un plan d'optimisation priorisé
#

Phase 1 — Audit des skills

1. Liste tous les skills installés avec :
   - hermes skills list
2. Pour chaque skill, vérifie :
   - sa date de dernière modification
   - sa pertinence pour un profil STIC / réseaux / DevOps
   - s'il est obsolète ou incomplet
3. Vérifie aussi les skills disponibles dans le hub :
   - hermes skills browse
   - Cherche spécifiquement :
     * skills liés à Docker, Python, réseau, git, CI/CD
     * skills d'optimisation de config Hermes
     * skills de synchronisation / backup
4. Signale les doublons, les skills morts, les skills à mettre à jour.

Phase 2 — Suggestion d'amélioration des skills

1. Pour chaque skill installé qui est obsolète ou incomplet :
   - Détermine ce qui manque (étapes, pièges, commandes obsolètes)
   - Propose un plan de correction avec skill_manage(action='patch')
2. Suggère jusqu'à 5 nouveaux skills à installer depuis le hub ou à créer.

Phase 3 — Audit de la synchronisation GitHub

Objectif : analyser comment cette instance Hermes sauvegarde et synchronise sa config sur GitHub.

1. Cherche les fichiers et scripts liés à la synchronisation :
   - Cherche des fichiers comme sync-vault.sh, sync.sh, backup.sh
   - Vérifie ~/.hermes/config.yaml pour la config
   - Regarde s'il y a un dossier hermes-config/ ou similaire
   - Vérifie les crons avec hermes cron list
2. Analyse la stratégie actuelle :
   - Qu'est-ce qui est sauvegardé ? (config, skills, memories, sessions ?)
   - Qu'est-ce qui ne l'est PAS et qui devrait l'être ?
   - La synchronisation est-elle bidirectionnelle ?
   - Y a-t-il des conflits possibles entre 2 instances (locale + VPS) ?
3. Vérifie les risques :
   - Les secrets (API keys, tokens) sont-ils commités par erreur ?
   - Y a-t-il des chemins absolus qui casseraient sur une autre machine ?
   - Les hooks git ou crons sont-ils bien configurés ?
4. Propose des améliorations :
   - Script de sync plus robuste
   - Gitignore adapté
   - Gestion des conflits entre instances
   - Automatisation supplémentaire si pertinent

Phase 4 — Optimisation générale de la config Hermes

1. Analyse config.yaml :
   - Y a-t-il des providers inutiles ?
   - Les timeouts sont-ils adaptés ?
   - La compression de contexte est-elle active ?
   - Les modèles par défaut sont-ils cohérents ?
2. Vérifie l'état des providers :
   - Quels providers sont configurés et fonctionnels ?
   - Quels sont les modèles de fallback en cas d'erreur ?
3. Propose des optimisations pour :
   - La vitesse (compression, caching)
   - La fiabilité (fallback providers, retry)
   - La sécurité (secrets, .env, gitignore)
   - La portabilité (chemins relatifs, scripts)

Phase 5 — Rapport final

Produis un résumé structuré avec :

1. Skills :
   - Installés : N actifs, N obsolètes, N à créer/supprimer
   - Recommandations : 3-5 actions concrètes prioritaires

2. Synchronisation GitHub :
   - Schéma actuel (en 2-3 lignes)
   - Problèmes identifiés (N)
   - Améliorations recommandées (liste priorisée)

3. Config Hermes :
   - Points forts
   - Points à améliorer
   - Actions immédiates (peut être fait maintenant)
   - Actions à long terme (nécessite réflexion)

4. Plan d'action priorisé sur 3 niveaux :
   - P0 : urgent (sécurité, perte de données)
   - P1 : important (amélioration quotidienne)
   - P2 : nice-to-have (optimisation, confort)

#

Règles :
- N'exécute PAS les modifications. Tu examines et tu proposes.
- Tu peux lire tous les fichiers mais ne rien écrire.
- Si un script de sync existe, décris-le sans le modifier.
- Ne commit rien sur GitHub.
- Ne supprime aucun fichier.
- Signale tout secret visible (API key en clair) comme une alerte de sécurité.
- Structure le rapport en sections claires, avec des listes et des priorités.
#
```

## Notes

- Inspecte seulement ; ne modifie rien.
- Si une commande suggérée échoue, note-la comme risque d’interruption, pas comme erreur fatale.
- Pour la partie GitHub, inclus systématiquement : secrets, chemins absolus, doublons, et gestion de conflits multi-instance.
