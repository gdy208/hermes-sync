---
name: ui-generation
description: Generate UI/HTML pages with design system skills (TypeUI) and strict anti-slop rules.
license: MIT
metadata:
  hermes:
    tags: [html, ui, design, typeui, css, frontend]
    related_skills: [typeui, claude-design, sketch, popular-web-designs]
---

# UI Generation

Use this skill when the user asks you to generate an HTML page, UI component, landing page, dashboard, mockup, or any visual web artifact.

## First: Load a Design System

Before writing any HTML, load a design system skill for visual tokens:

1. **Ask or infer the style** — the user might say "entreprise", "dark", "minimal", etc.
2. **Find the matching TypeUI skill** — 62 skills are installed as `typeui-<slug>`:
   - `typeui-paper` — minimal, calme, tactile
   - `typeui-corporate` — professionnel, bleu, structuré
   - `typeui-enterprise` — dark mode, cloud vibe
   - `typeui-neobrutalism` — jaune/violet, bordures bold
   - `typeui-bento` — grille modulaire
   - `typeui-material` — Material Design Google
   - `typeui-minimal` — ultra simple
   - `typeui-clean` — propre, aéré
   - `typeui-retro` — vintage
   - `typeui-modern` — moderne épuré
   - `typeui-shadcn` — shadcn/ui
   - ... et 51 autres disponibles
3. **Load it**: `skill_view(name='typeui-<slug>')` to read the SKILL.md
4. **Extract tokens**: colors, typography (fonts + scale), spacing, radii, component rules

## Design Tokens Setup

Map the loaded skill's tokens to CSS custom properties:

```css
:root {
  --primary:      /* from skill palette */
  --secondary:    /* from skill palette */
  --success:      /* from skill palette */
  --warning:      /* from skill palette */
  --danger:       /* from skill palette */
  --surface:      /* from skill palette */
  --text:         /* from skill palette */
  --text-muted:   /* derived, ~60% opacity of text */
  --border:       /* derived, from text */
  --radius:       /* from skill (0 for brutalism, 8px+ for enterprise) */
}
```

For typography, load the Google Font(s) the skill defines and set the scale as CSS.

## Design Variants

When the user wants to compare styles, generate 2-3 variants of the SAME content in different TypeUI design systems. Name files `ai-deploy-<style>.html` and offer all for comparison.

### SVG Replacement Reference

See `references/svg-icons.md` for the full collection of hand-coded SVGs to replace emoji.

## ⚠️ INTERDICTION ABSOLUE : Zéro émoji dans le design UI

**JAMAIS, JAMAIS, JAMAIS d'émoji** (🔥, ⚡, ✅, 🤖, 💰, ☁️, ▶, 📊, 🔄, 🔐, 🎨, ❌, 💛, etc.) dans un site, une landing page, un dashboard, un composant UI, une maquette, ou tout artifact HTML/CSS.

Les émojis dans le design sont un marqueur universel d'agent IA. Ça rend le rendu générique et amateur. Les designers professionnels et les vrais produits n'utilisent pas d'émojis comme icônes UI.

### Remplacer les émojis par :

| Émoji interdit | Remplacer par |
|---|---|
| 🔥 | Badge texte "Nouveau" ou "Nouveauté" |
| ⚡ | SVG éclair : `<svg viewBox="0 0 24 24"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg>` |
| 🤖 | SVG robot : `<svg viewBox="0 0 24 24"><rect x="4" y="6" width="16" height="12" rx="2"/><circle cx="9" cy="10" r="1"/><circle cx="15" cy="10" r="1"/><path d="M10 14h4"/><path d="M12 6V2"/><path d="M8 18v2"/><path d="M16 18v2"/></svg>` |
| 🔐 | SVG cadenas : `<svg viewBox="0 0 24 24"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>` |
| ☁️ | SVG nuage : `<svg viewBox="0 0 24 24"><path d="M17.5 19H9a7 7 0 1 1 6.71-9h1.79a4.5 4.5 0 1 1 0 9Z"/></svg>` |
| 📊 | SVG barres : `<svg viewBox="0 0 24 24"><line x1="12" y1="20" x2="12" y2="10"/><line x1="18" y1="20" x2="18" y2="4"/><line x1="6" y1="20" x2="6" y2="16"/></svg>` |
| 🔄 | SVG rotation : `<svg viewBox="0 0 24 24"><polyline points="23 4 23 10 17 10"/><path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"/></svg>` |
| ▶ | Rien (juste le texte) ou SVG play |
| 💰 | Rien (juste le texte du bouton) |
| ✅ / ❌ | Textes "Succès" / "Erreur" ou SVGs check/croix |

Tous les SVGs ci-dessus utilisent `stroke="currentColor" stroke-width="2" fill="none"` pour hériter de la couleur du design system.

### Règle d'or
- **Ne jamais inventer d'émoji** dans le design, même "joli" ou "discret".
- Si l'utilisateur fournit du contenu texte contenant des émojis, respecter SA copie. Ne pas en ajouter.
- Pas d'icône du tout > émoji. La typographie, l'espacement et les couleurs portent le sens.

## Structure

### For a landing/site vitrine page:
```
Header (sticky) → Hero → Clients → Services → Process/Aproach → Tech stack → Case studies → CTA → Footer
```

### For a dashboard:
```
Sidebar/Header → Stats row → Charts → Tables → Activity feed
```

### For a component:
Follow the skill's component rules and states (default, hover, focus, active, disabled, loading, error).

## HTML/UX Standards

- Semantic HTML (`<header>`, `<nav>`, `<section>`, `<footer>`, etc.)
- CSS custom properties (no hard-coded values beyond token definitions)
- CSS Grid for layout
- Responsive breakpoints (768px as the main mobile breakpoint)
- Real focus-visible states on all interactive elements
- WCAG 2.2 AA color contrast
- `prefers-reduced-motion` for non-trivial animations
- Google Fonts via `<link>` (one or two families max)
- Self-contained HTML file (inline `<style>`, no build step)

## Anti-Slop Checklist (score yourself)

Before showing the result, check:
- [ ] No emoji used as UI decoration
- [ ] Design tokens come from the skill, not default model values
- [ ] Not centered-hero + 3 equal cards (unless it's a Decide/Learn surface)
- [ ] Not using indigo/violet as default accent (unless the skill says so)
- [ ] No glassmorphism unless the skill specifies it
- [ ] Real hover/focus states
- [ ] Responsive layout
- [ ] Semantic HTML
- [ ] Tokens in CSS vars, not raw values

## Related TypeUI Skills (all 62)

A categorized reference of all 62 TypeUI skills is available at `references/typeui-skills.md` within this skill directory.

Run `ls ~/.hermes/skills/typeui-*/SKILL.md 2>/dev/null | sed 's|.*/typeui-||;s|/SKILL.md||'` to get the full up-to-date list.
