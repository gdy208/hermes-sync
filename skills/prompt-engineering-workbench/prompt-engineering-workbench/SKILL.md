---
name: prompt-engineering-workbench
description: Méthode complète de conception de prompts "en entonnoir à 2 étages" — profilage agent, grille d'analyse 7+1 points, template 9 directives, règles de rédaction. Héritée de l'audit du prompt IMSS. Invoque cette skill quand l'utilisateur veut générer un prompt structuré et professionnel pour déléguer une tâche complexe à une IA (code, design, rédaction, analyse, architecture, etc.).
tags:
  - prompt-engineering
  - meta-prompt
  - template
  - methodology
---

# Prompt Engineering Workbench

## Quand l'utiliser

L'utilisateur a besoin de :
- Concevoir un **prompt long et structuré** pour déléguer une tâche complexe à une IA
- Analyser un prompt existant pour comprendre sa structure et l'améliorer
- Générer un prompt **prêt à copier-coller** (sans méta-commentaires, sans texte autour)
- Appliquer la **méthode décortiquée sur le prompt IMSS** à un autre domaine (code, design, rédaction, architecture, data science, etc.)
- Audit la qualité d'un prompt existant

Ne PAS utiliser pour : des questions simples en un tour, de la conversation courante, ou quand l'utilisateur demande juste une réponse directe sans structure particulière.

## Architecture générale : le modèle en entonnoir à 2 étages

```
┌─────────────────────────────────────────────────────────────┐
│   ÉTAGE 1 : Le prompt qu'on construit (le travail)          │
│                                                             │
│   1. Profilage de l'agent (rôle, compétences, techniques)   │
│   2. Mission + anti-instructions (quoi faire et NE PAS)     │
│   3. Grille d'analyse (checklist d'exploration)             │
│   4. Règles de rédaction (contraintes du prompt final)      │
│   5. Template de sortie (structure du prompt final)         │
│   6. Phase de vérification (relecture avant livraison)      │
└─────────────────────┬───────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────────┐
│   ÉTAGE 2 : Le prompt produit (livrable)                    │
│                                                             │
│   Prompt autonome, prêt à copier-coller,                    │
│   structuré selon le template 9 directives.                 │
│   Destiné à une IA (Claude, Codex, Cursor, ChatGPT, etc.)  │
└─────────────────────────────────────────────────────────────┘
```

## Workflow en 6 phases

### Phase 1 : Profilage de l'agent (le prompteur)

Identifier et lister explicitement les techniques de prompt engineering à activer. Rédiger une phrase d'assignation de rôle percutante.

**Les 9 techniques à activer (à recopier dans le prompt en préambule) :**

1. **Zero-shot & Few-shot prompting** — capacité à répondre sans ou avec peu d'exemples
2. **Templates adaptatifs** — ajustement du format selon le cas
3. **Assignation de rôle** — personnification experte (préciser le domaine, le niveau)
4. **Perspective ciblée (audience)** — à qui s'adresse la réponse (développeur, manager, novice…)
5. **Personnalité et ton calibré** — ton professionnel, percutant, amical, mentor, provocateur…
6. **Accès contextuel à la connaissance** — le modèle utilise TOUT ce qu'il sait sur le domaine
7. **Raisonnement en chaîne (Chain-of-Thought)** — raisonner étape par étape avant de répondre
8. **Instructions personnalisées claires** — contraintes explicites (ce qu'il faut inclure, exclure)
9. **Exemples** — 1 à 3 exemples pour caler le style, la structure, ou le niveau de détail

**Pattern de profilage type :**
```
Tu es un expert en [domaine] pour [contexte spécifique].
Tu maîtrises les techniques de prompt engineering suivantes :
[liste des techniques activées]
```

### Phase 2 : Définir la mission

Rédiger en une phrase claire l'objectif, puis ajouter :
- **Sous-tâches détaillées** (en checklist numérotée)
- **Anti-instructions** (ce qu'il NE faut PAS faire, en bloc dédié)
- **Critères de succès** (comment on saura que le prompt est bon)

**Pattern :**
```
Ta mission est de [verbe] [objet] pour [but final].

Étapes à suivre :
1. ...
2. ...
3. ...

⚠️ CE QUE TU NE DOIS PAS FAIRE :
- Ne pas [comportement indésirable]
- Ne pas [autre comportement]

Critères de succès :
- [critère mesurable 1]
- [critère mesurable 2]
```

### Phase 3 : Grille d'analyse (CoT séquentiel)

Quand la mission demande une exploration avant rédaction, fournir une checklist d'analyse obligatoire qui force le raisonnement étape par étape.

**Grille d'analyse par défaut (UI/design) :** à adapter selon le domaine

1. **Structure et mise en page** — disposition générale, type de grille (flexbox, grid), sections principales (header, hero, contenu, footer), ordre d'apparition
2. **Palette de couleurs** — couleurs dominantes, accent, arrière-plans, texte, codes hexadécimaux estimés
3. **Typographie** — familles de polices, tailles relatives, graisses, hiérarchie (titres H1-H6 vs corps)
4. **Composants** — nav, boutons (formes, padding, border-radius), cartes, formulaires, icônes, images, style (ombres, bordures)
5. **Espacements et proportions** — marges, paddings, densité visuelle, largeur des conteneurs (fixe %, max-w)
6. **Interactions et animations** — hover, transitions, scroll, chargement, éléments dynamiques
7. **Comportement responsive** — breakpoints, changements de disposition si visibles
8. **États des composants** — hover, active, focus, disabled, loading, empty, error (manque souvent, à ajouter)

**Grille générique (tout domaine) :** adapter les 7 points au domaine cible
1. Contexte et finalité
2. Public cible
3. Structure et organisation
4. Ton et style
5. Contraintes techniques
6. Exemples attendus
7. Critères de qualité
8. Anti-patterns à éviter

### Phase 4 : Règles de rédaction du prompt final

Le prompt généré (étage 2) doit respecter ces 7 règles :

- **R1 — Autonome et précis** : formulé comme une consigne directe à l'IA de destination, sans références externes nécessaires
- **R2 — Ordre séquentiel** : décrire chaque section de haut en bas, dans l'ordre d'apparition (ou logique)
- **R3 — Stack technique adaptée** : indiquer la technologie la plus simple adaptée au rendu (HTML/CSS vanilla, Tailwind, React, Python…)
- **R4 — Fidélité + placeholders** : préciser le niveau de fidélité attendu (pixel-perfect, proche, inspiré) et utiliser du contenu factice là où le réel n'est pas disponible
- **R5 — Valeurs explicites** : donner codes couleurs, polices, tailles, espacements de façon chiffrée
- **R6 — Prêt à copier-coller** : aucun méta-commentaire, aucun texte autour du prompt, il commence par le rôle et finit par la dernière instruction
- **R7 — Vérifiable** : inclure un moyen de valider le résultat (ex: « le rendu doit tenir sur un écran 1920×1080 sans scroll vertical pour la hero section »)

### Phase 5 : Template de sortie (structure du prompt final)

Utiliser ce squelette de **9 directives** pour structurer la sortie. L'ordre peut varier selon le domaine.

```
[DIRECTIVE 1] RÔLE ASSIGNÉ
"Tu es un expert en [domaine]..."
Techniques activées : [liste]

[DIRECTIVE 2] OBJECTIF CLAIR
"Ton objectif est de [résumé en une phrase]"

[DIRECTIVE 3] CONTEXTE PERTINENT
"Cadre : [public cible, style, plateforme, contraintes techniques]"

[DIRECTIVE 4] PERSPECTIVE CIBLE
"Tu t'adresses à [qui reçoit/révise le travail]"
"Adapte le ton pour [type de lecteur]"

[DIRECTIVE 5] STYLE DE COMMUNICATION
"Sois [professionnel / amical / provocateur / mentor / technique]"
"[Citation ou exemple du ton attendu]"

[DIRECTIVE 6] FORMAT ATTENDU
"Produis [type de sortie : code, analyse, plan, tableau, texte argumenté]"
"Structure : [détail de l'organisation]"

[DIRECTIVE 7] RAISONNEMENT (CoT)
"Avant de répondre, suis ces étapes :
1. [étape d'analyse]
2. [étape de synthèse]
3. [étape de production]"

[DIRECTIVE 8] INSTRUCTIONS PERSONNALISÉES
"Contraintes : "
"- Longueur maximale : [X tokens/lignes]"
"- Inclus : [élément obligatoire]"
"- Exclus : [élément interdit]"
"- [autre contrainte spécifique]"

[DIRECTIVE 9] EXEMPLES (optionnel)
"Exemple de ce qui est attendu :
[Exemple 1 : court]"

[DONNÉES D'ENTRÉE]
"[lien, capture, fichier, spécification…]"
```

### Phase 6 : Vérification avant livraison

Avant de livrer le prompt final, l'agent doit se poser ces questions :

- [ ] Le prompt commence-t-il directement par le rôle ? (R6)
- [ ] Toutes les directives 1 à 9 sont-elles présentes ou justifiées absentes ?
- [ ] Les valeurs (couleurs, tailles, polices) sont-elles explicites et chiffrées ? (R5)
- [ ] Y a-t-il des références externes non résolues ? (R1)
- [ ] Le format attendu est-il clair pour l'IA de destination ? (R6)
- [ ] Les anti-instructions sont-elles présentes si nécessaire ? (Phase 2)
- [ ] Le prompt tiendrait-il dans la fenêtre de contexte de l'IA cible ?
- [ ] Y a-t-il au moins un critère de succès vérifiable ? (R7)

## Préférences utilisateur

### Ton et style de communication

Pour cet utilisateur, **privilégier un ton direct et assertif** qui commence par l'action. Le pattern "Je commence par [verbe d'action]..." (ex: "Je commence par auditer ton matos en détail.") est particulièrement apprécié car il montre une prise d'initiative et une structure claire.

**Ce qu'il faut faire :**
- Ouvrir par une phrase d'action qui annonce ce qu'on va faire
- Être direct sur les constats ("Problème identifié : ...")
- Proposer des solutions concrètes immédiatement
- Utiliser des énumérations et tableaux pour structurer

**Ce qu'il faut éviter :**
- Ton passif ou hésitant ("Je pourrais peut-être...")
- Questions ouvertes sans proposition ("Que faire ?" sans offrir de choix)
- Excuses ou précautions excessives avant d'agir
- Réponses verbeuses qui noient l'information utile

Ce style s'applique à toutes les interactions (debug, setup, analyse, tutorat), pas seulement à la rédaction de prompts structurés.

## Intégration avec `/goal` pour les tâches complexes

Certains prompts mènent à des tâches qui demandent **plusieurs tours de travail** (corriger tous les tests, migrer un service, refactoriser un module entier). Dans ce cas, `/goal` + completion contract transforme un prompt one-shot en boucle auto-continue avec preuve de complétion.

### Quand proposer `/goal`

Proposer l'utilisation de `/goal` quand la tâche :
- Implique **plusieurs étapes itératives** (corriger → tester → re-corriger)
- Nécessite de **vérifier le résultat** avant de déclarer terminé
- Serait autrement relancée manuellement 3+ fois ("continue", "et maintenant?", "il en reste?")
- Peut être **gâtée par un juge** qui dit "done" trop tôt sans preuve

### Quand NE PAS proposer `/goal`

- Questions simples en un tour
- Tâches conversationnelles (brainstorming, explication)
- Quand l'utilisateur veut un contrôle tour-par-tour
- Tâches où le contexte sera vite dépassé (limits de tokens)

### Template de completion contract

Quand on génère un prompt pour une tâche complexe, inclure un completion contract structuré :

```
/goal draft [objectif en langage naturel]
```

Ou en écriture inline :

```
/goal [objectif]
outcome: [état final attendu — une seule phrase]
verify: [commande/test/artefact qui PROUVE la complétion]
constraints: [ce qu'il ne faut PAS casser]
boundaries: [périmètre d'intervention — fichiers, dossiers, services]
stop when: [condition d'arrêt — quand il faut demander de l'aide]
```

### Exemples par domaine

**Code / DevOps :**
```
/goal Fix all failing tests and get CI green
outcome: all tests pass, CI pipeline succeeds
verify: pytest exits 0 and GitHub Actions shows green
constraints: don't change public API signatures
boundaries: only touch src/ and tests/
stop when: a migration or infra change is needed
```

**Rédaction :**
```
/goal Draft a 2000-word blog post on container security
outcome: complete, publish-ready article in Markdown
verify: word count 1800-2200, covers 3 attack vectors, includes code examples
constraints: tone must be technical but accessible, no marketing fluff
boundaries: single file output, no external research needed
stop when: user asks for a specific angle or audience shift
```

**Architecture / Design :**
```
/goal Design a microservices architecture for an e-commerce platform
outcome: architecture diagram + component spec + data flow
verify: diagram covers auth, catalog, cart, payments, shipping; each service has API contract
constraints: must be deployable on a single VPS initially
boundaries: design only, no implementation
stop when: scaling requirements exceed single-server capacity
```

### Intégration dans le workflow existant

Dans le workflow en 6 phases, `/goal` s'intègre naturellement :

1. **Phase 2 (Mission)** — quand la mission contient des étapes itératives, ajouter la section "Completion Contract" avec les 5 champs
2. **Phase 5 (Template)** — ajouter le bloc `/goal` à la fin du prompt généré, après les données d'entrée
3. **Phase 6 (Vérification)** — vérifier que le `verify:` contient une commande testable, pas une description vague

### Prompt généré type avec `/goal`

```
[RÔLE ASSIGNÉ]
Tu es un expert en [domaine]...

[OBJECTIF CLAIR]
...

[CONTEXTE PERTINENT]
...

[INSTRUCTIONS PERSONNALISÉES]
...

[DONNÉES D'ENTRÉE]
...

[GOAL — COMPLETION CONTRACT]
/goal draft [objectif en langage naturel]
```

L'utilisateur tape ensuite `/goal draft ...` et Hermes génère le contract complet. Le juge vérifie la complétion avec des preuves concrètes, pas des affirmations.

### Avantages de cette approche

| Sans `/goal` | Avec `/goal` + contract |
|---|---|
| Agent fait 1 tour et s'arrête | Agent tourne automatiquement |
| "C'est fait" (sans preuve) | "C'est fait" SEULEMENT si `verify:` passe |
| Relances manuelles 3-4 fois | Surveillance passive, intervention rare |
| Critères vagues | Critères mesurables et vérifiables |

## Pièges à éviter (pitfalls)

1. **Prompt trop long** : le prompt final doit tenir dans le contexte de l'IA cible. Si >4K tokens, envisager de le scinder ou de simplifier.
2. **Mélange des niveaux** : ne pas inclure d'instructions *sur* le prompt dans le prompt final. Les consignes « tu dois analyser avant de rédiger » sont pour l'agent générateur, pas pour l'IA de code.
3. **Absence d'anti-instructions** : toujours préciser ce qu'il ne faut PAS faire. C'est aussi important que ce qu'il faut faire.
4. **Exemples manquants** : un exemple court vaut mieux que pas d'exemple du tout. Même un exemple partiel ancre le style.
5. **Ton inadapté** : adapter le ton à la tâche. Un prompt pour coder doit être technique et précis ; un prompt pour créer du contenu marketing peut être plus inspirant.
6. **Oubli des placeholders** : si le contenu réel n'est pas disponible, le dire explicitement plutôt que de laisser l'IA inventer du contenu qui serait pris pour réel.
7. **Surcharge de directives** : les 9 directives sont un guide, pas une obligation. Si une directive n'a pas de sens pour la tâche, l'omettre plutôt que de la remplir artificiellement.
8. **Oubli de `/goal` pour les tâches itératives** : quand la mission demande plusieurs tours (corriger → tester → re-corriger), proposer un completion contract structuré (`outcome`, `verify`, `constraints`, `boundaries`, `stop_when`) au lieu de laisser l'agent s'arrêter après un tour. Un `verify:` vague ("ça devrait marcher") est aussi inutile que pas de verify du tout — exiger une commande testable.

## Exemples d'application

### Exemple 1 : Analyse de site UI → Prompt pour IA de code
*(le cas original qui a inspiré la méthode)*

**Domaine** : Design front-end
**Techniques activées** : CoT, assignation de rôle, template adaptatif, instructions personnalisées
**Phases actives** : 1→2→3→4→5→6 (complètes)
**Piège évité** : anti-instruction explicite « NE PAS coder » pour éviter que l'agent exécute la tâche au lieu de la préparer

### Exemple 2 : Rédaction d'article de blog

**Domaine** : Rédaction / Content marketing
**Grille d'analyse adaptée** : 1. Sujet et angle → 2. Public cible → 3. Ton et voix → 4. Structure (intro, corps, conclusion) → 5. Mots-clés SEO → 6. Longueur → 7. Appels à l'action → 8. Exemples de posts similaires
**Stack technique** : Markdown
**Règles particulières** : R4 (données chiffrées à utiliser), R5 (longueur explicite en mots)

## Notes de version

- **v1.0** — Création initiale. Méthode décortiquée du prompt IMSS, audit complet, architecture 2 étages, 6 phases, template 9 directives, 7 pièges, 1 exemple.
