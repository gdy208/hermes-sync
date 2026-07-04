# Pourquoi l'installation d'Hermes est lente sur Termux ? (Compilation vs Interprétation)

Quand un étudiant installe Hermes sur Termux, il voit des dizaines de
messages "Building wheel..." qui prennent 20 à 40 minutes. Ce document
explique pourquoi — c'est une opportunité pédagogique pour comprendre
la différence entre langages compilés et interprétés.

## Le constat

Sur PC (Linux x86_64) :
```
pip install jiter → télécharge .whl déjà compilé → 3 secondes ✅
```

Sur Termux (ARM Android) :
```
pip install jiter → prend le code source Rust → compile 30 min 🔥
```

## Langages interprétés vs compilés

### Langages compilés (C, Rust, Go)

```rust
fn main() {
    println!("Bonjour");
}
```

Le code source est **traduit en langage machine** (binaire 0 et 1) AVANT
d'être exécuté — c'est la **compilation** :

```
Code source (Rust/C) → Compilation → Binaire (.so fichier objet)
```

Le binaire contient des instructions directement compréhensibles par le CPU.
Exécution : **très rapide**, le CPU exécute directement.

### Langages interprétés (Python, JavaScript, Bash)

```python
print("Bonjour")
```

Pas de traduction en binaire à l'avance. Un **interpréteur** lit le code
source ligne par ligne et l'exécute immédiatement.

**Mais c'est plus nuancé :** Python ne lit pas vraiment ligne par ligne.
Il fait une **compilation légère** en **bytecode** (`.pyc`) :

```
Python (source) → Bytecode (.pyc) → Machine virtuelle CPython → CPU
```

### Le spectre complet

| Langage | Traduction | Exécution |
|---------|-----------|-----------|
| **Rust/C/Go** | → Binaire CPU direct | Rapide — CPU natif |
| **Java/C#** | → Bytecode (JVM) | JIT* compile à chaud |
| **Python** | → Bytecode (.pyc) | VM lit le bytecode |
| **Bash** | Aucune | Interprète ligne par ligne |

*\*JIT = Just-In-Time Compilation — transforme le bytecode en binaire
pendant l'exécution pour les parties qui tournent souvent.*

## Pourquoi des packages Rust dans un projet Python ?

Les auteurs écrivent les parties **critiques en performances** en Rust/C :

| Package | Langage | Utilité |
|---------|---------|---------|
| `jiter` | Rust | Parsing JSON (remplace `json` de Python) |
| `uvloop` | Cython | Boucle d'événements ultra-rapide |
| `pydantic-core` | Rust | Validation de données |
| `watchfiles` | Rust | Surveillance de fichiers |
| `regex` | C | Expressions régulières |

Ces packages sont **95% Python** pour l'API publique, mais le cœur
(performances) est en Rust/C. C'est ce cœur qu'on compile sur Termux.

## Pourquoi Termux compile et pas le PC ?

Quand tu fais `pip install` :

1. pip regarde s'il existe une **wheel** (`fichier.whl`) pour ton système
   — un binaire déjà compilé
2. Si la wheel existe → téléchargement de 2 secondes ✅
3. Si elle n'existe pas → prend le code source → compilation locale 🔥

Pour le PC (Linux x86_64, macOS, Windows) → des wheels existent pour
pratiquement tous les packages. Le serveur de PyPI les distribue.

Pour Termux (Android ARM) → **pas de wheels** (trop peu d'utilisateurs,
plateforme non standard). Donc pip compile depuis le code source.

## Ce qui se passe concrètement sur le téléphone

Pendant "Building wheel for jiter", le téléphone fait :
1. Lance le compilateur Rust (`rustc`)
2. Charge tout le code source de jiter (des centaines de fichiers)
3. Optimise et traduit en binaire ARM
4. Génère un fichier `.so` (bibliothèque partagée)
5. pip l'installe dans l'environnement virtuel

C'est un processus lourd et séquentiel — un package après l'autre.
Sur un Helio G99, les plus longs sont :

| Package | Temps estimé |
|---------|--------------|
| `jiter` | 8-12 min |
| `pydantic-core` | 5-8 min |
| `uvloop` | 3-5 min |
| `watchfiles` | 3-5 min |
| `orjson` | 2-4 min |
| `regex` | 1-2 min |

Une fois compilés, ces binaires `.so` sont stockés et n'ont plus jamais
besoin d'être recompilés (sauf si tu mets à jour le package).

## À retenir pour l'étudiant

- **Ce délai est normal** — pas d'erreur, pas de bug
- **C'est un one-shot** — la prochaine fois que tu lances Hermes, tout
  est déjà compilé
- **La lenteur est le prix à payer** pour faire tourner des outils de
  PC sur un processeur de téléphone
- **Rassure l'étudiant** : montre-lui que des lignes défilent, que la
  barre de progression avance. Le plus dur est le début (jiter).
