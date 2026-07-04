# TypeUI Design Skills — Référence Rapide

62 skills installés sous `~/.hermes/skills/typeui-*/`.

## Par catégorie

### Design systems complets
| Slug | Style |
|------|-------|
| material | Material Design Google — surfaces, motion, thèmes dynamiques |
| shadcn | shadcn/ui — monochrome, utilitaire, minimal |
| corporate | Professionnel, structuré, bleu `#3B82F6`, Open Sans |
| enterprise | Dark theme cloud, IBM Plex, verre, bleu `#0C5CAB` |
| clean | Simple, aéré, lisible |
| minimal | Ultra minimal, blanc, espace |
| modern | Épuré contemporain |

### Créatifs et expressifs
| Slug | Style |
|------|-------|
| neobrutalism | Bordures bold, jaune `#FDC800` + violet `#432DD7`, chaud |
| bento | Grille modulaire, cartes, hiérarchie claire |
| paper | Style papier, calme, tactile |
| neo | Néon, glow |
| retro | Vintage, nostalgique |
| vintage | Rétro, vieilli |
| fantasy | Créatif, jeu, imaginatif |
| fiction | Ludique, cartoon |
| artistic | Artistique, expressif |
| colorful | Coloré, vibrant |
| vibrant | Vif, dynamique |
| dramatic | Théâtral, contraste fort |
| expressive | Expressif, personnalité |
| creative | Créatif, jeu typographique |

### UX / Interfaces spécifiques
| Slug | Style |
|------|-------|
| agentic | IA agentique, minimal |
| ant | Enterprise structuré (Ant Design) |
| claude | Style recherche, pierre chaude |
| codex | Radical minimal, toile blanche |
| cosmic | Sci-fi, néon, futuriste |
| futuristic | Tech, moderne, avant-garde |
| geometric | Géométrique, structuré |
| glassmorphism | Verre, flou, translucide |
| gradient | Dégradés, transitions |
| claymorphism | Argile, 3D doux |
| neumorphism | Néomorphe, extrudé doux |
| skeumorphism | Réaliste, texture |
| flat | Plat, 2D, minimal |
| dithered | Tramé, pixels |
| riso | Risographie, 2 couleurs |

### Contenu / Média
| Slug | Style |
|------|-------|
| editorial | Magazine, serif, élégant |
| storytelling | Narratif, visuel |
| impeccable | Éditorial-poster |
| terracotta | Terre cuite, chaud |
| refined | Raffiné, serif |
| square | Gracieux, délicat |
| spacious | Ample, aéré |
| sleek | Moderne, lisse |
| impeccable | Éditorial contemporain |
| premium | Apple-like, luxe |
| luxury | Luxe, premium |
| power | Dark haut de gamme |
| professional | Pro, moderne |

### Thèmes gaming / Rétro
| Slug | Style |
|------|-------|
| pacman | Arcade, pixels, rétro |
| tetris | Blocs, jeu, coloré |
| sega | Arcade, jeu |
| matrix | Cyber, sombre, Matrix |
| mono | Monospace, matrix-like |
| sketch | Carnet, crayonné, friendly |
| hand-drawn | Dessiné à la main |

### Fonctionnels
| Slug | Style |
|------|-------|
| levels | Conversion, guidance |
| lingo | Ludique, éducatif, friendly |
| friendly | Approchable, arrondi |
| immersive | Expo, interactif |
| perspective | Profondeur, isométrique |
| mono | Monospace, technique |

## Commande pour liste à jour

```bash
ls ~/.hermes/skills/typeui-*/SKILL.md 2>/dev/null | sed 's|.*/typeui-||;s|/SKILL.md||' | sort
```

## Utilisation

```
skill typeui-<slug>    → charge les tokens dans la session
skill_view(name='typeui-<slug>')  → lit le SKILL.md complet
```

Puis génère l'UI en suivant les tokens extraits.
