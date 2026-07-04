#!/usr/bin/env python3
"""
Agentic AI Daily Briefing - Collecteur de données
Récupère les infos brutes depuis plusieurs sources.
Output: JSON compact vers stdout (max ~25K chars).
"""

import json
import sys
import datetime
import re
import time
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError

USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64) Hermes-Agentic-Briefing/1.0"
TIMEOUT = 15

# --- Utilities ---

def fetch(url, headers=None):
    req = Request(url, headers={"User-Agent": USER_AGENT, **(headers or {})})
    try:
        with urlopen(req, timeout=TIMEOUT) as r:
            return r.read().decode("utf-8", errors="replace")
    except Exception as e:
        return None

def fetch_json(url):
    t = fetch(url)
    if t:
        try:
            return json.loads(t)
        except json.JSONDecodeError:
            return None
    return None

def shorten(text, maxlen=200):
    if not text:
        return ""
    text = re.sub(r'\s+', ' ', text).strip()
    if len(text) > maxlen:
        return text[:maxlen] + "..."
    return text

# Try to use bs4 if available
try:
    from bs4 import BeautifulSoup
    HAS_BS4 = True
except ImportError:
    HAS_BS4 = False


# --- Collectors ---

def collect_hf_papers():
    """Daily papers from Hugging Face."""
    html = fetch("https://huggingface.co/papers")
    if not html:
        return []

    papers = []
    # Strategy 1: find links with /papers/XXXXX.XXXXX
    for m in re.finditer(r'href=["\']/papers/(\d+\.\d+)["\'][^>]*>(.*?)</a>', html):
        paper_id = m.group(1)
        title = re.sub(r'<[^>]+>', '', m.group(2)).strip()
        if title and len(title) > 10:
            papers.append({"t": title, "u": f"https://huggingface.co/papers/{paper_id}"})

    # Strategy 2: bs4 if available
    if HAS_BS4 and not papers:
        soup = BeautifulSoup(html, 'lxml')
        for a in soup.select('a[href*="/papers/"]'):
            href = a.get('href', '')
            title = a.get_text(strip=True)
            if '/papers/' in href and title and len(title) > 10:
                paper_id = href.split('/papers/')[-1].split('/')[0]
                papers.append({"t": title, "u": f"https://huggingface.co/papers/{paper_id}"})

    # Dedup + filter junk
    seen = set()
    result = []
    for p in papers:
        t = p['t']
        # Skip non-title entries (author counts, etc.)
        if t.startswith('·') or len(t) < 10 or t.startswith(' ') or t.startswith('-'):
            continue
        if t not in seen:
            seen.add(t)
            result.append(p)
    return result[:12]


def collect_hermes_releases():
    """Latest Hermes Agent GitHub releases."""
    data = fetch_json("https://api.github.com/repos/nousresearch/hermes-agent/releases?per_page=3")
    if not data:
        return []
    releases = []
    for rel in data[:3]:
        if isinstance(rel, dict):
            body = rel.get("body", "") or ""
            # Extract first meaningful paragraph
            body_clean = re.sub(r'#{1,6}\s.*?\n', '', body)
            body_clean = re.sub(r'\*\*.*?\*\*', '', body_clean)
            body_clean = shorten(re.sub(r'\n+', ' ', body_clean), 300)
            releases.append({
                "t": rel.get("name", rel.get("tag_name", "")),
                "d": rel.get("published_at", "")[:10],
                "u": rel.get("html_url", ""),
                "body": body_clean,
            })
    return releases


def collect_hn_ai_stories():
    """Top AI-related Hacker News stories."""
    ids = fetch_json("https://hacker-news.firebaseio.com/v0/topstories.json")
    if not ids:
        return []

    keywords = re.compile(r'ai|agent|llm|gpt|claude|langchain|prompt|model|autonomous|'
                          r'deepseek|mistral|open.?source|coding|devops', re.IGNORECASE)
    stories = []
    for sid in ids[:80]:
        item = fetch_json(f"https://hacker-news.firebaseio.com/v0/item/{sid}.json")
        if not item or not isinstance(item, dict):
            continue
        title = item.get("title", "")
        score = item.get("score", 0) or 0
        if keywords.search(title) and score >= 3:
            stories.append({
                "t": title,
                "u": item.get("url", f"https://news.ycombinator.com/item?id={sid}"),
                "s": score,
            })
        if len(stories) >= 8:
            break
        time.sleep(0.05)
    return stories


def collect_openrouter_notable():
    """Get notable/recent models from OpenRouter, with price as floats."""
    data = fetch_json("https://openrouter.ai/api/v1/models")
    if not data:
        return []

    models = data.get("data", [])
    notable = []
    for m in models:
        if not isinstance(m, dict):
            continue
        mid = m.get("id", "")
        pricing = m.get("pricing", {})
        try:
            p_price = float(pricing.get("prompt", 0)) * 1000
            c_price = float(pricing.get("completion", 0)) * 1000
        except (ValueError, TypeError):
            p_price, c_price = 0, 0

        # Skip models with invalid pricing
        if p_price < 0 or c_price < 0:
            continue

        notable.append({
            "id": mid,
            "ctx": m.get("context_length", 0),
            "p$": round(p_price, 6),
            "c$": round(c_price, 6),
        })
    # Filter invalid pricing
    # Sort by context length desc, take top 30
    notable.sort(key=lambda x: -(x['ctx'] or 0))
    return notable[:30]


def collect_anthropic_blog():
    """Latest Anthropic newsroom posts."""
    html = fetch("https://www.anthropic.com/blog")
    if not html:
        return []

    posts = []
    # Pattern: links to /news/... containing a title in <strong> or heading
    for m in re.finditer(r'<a[^>]*href=["\'](/news/[^"\']+)["\'][^>]*>(.*?)</a>', html, re.DOTALL):
        url_path = m.group(1)
        inner = m.group(2)
        # Extract text from <strong> or heading tags
        title_m = re.search(r'<(?:strong|h[1-6])[^>]*>(.*?)</(?:strong|h[1-6])>', inner, re.DOTALL | re.IGNORECASE)
        if title_m:
            title = re.sub(r'<[^>]+>', '', title_m.group(1)).strip()
            if title and len(title) > 10:
                posts.append({"t": title, "u": f"https://www.anthropic.com{url_path}"})

    # Fallback: try finding any heading inside the link
    if not posts:
        for m in re.finditer(r'<a[^>]*href=["\'](/(?:news|blog)/[^"\']+)["\'][^>]*>.*?<(?:h[1-6]|strong|div[^>]*class[^>]*title)[^>]*>(.*?)</(?:h[1-6]|strong|div)>', html, re.DOTALL):
            title = re.sub(r'<[^>]+>', '', m.group(2)).strip()
            if title and len(title) > 10:
                posts.append({"t": title, "u": f"https://www.anthropic.com{m.group(1)}"})

    seen = set()
    result = []
    for p in posts:
        if p['t'] not in seen:
            seen.add(p['t'])
            result.append(p)
    return result[:6]


def collect_prompting_papers():
    """Recent arXiv papers on prompting / agents."""
    url = ("http://export.arxiv.org/api/query?"
           "search_query=(all:prompting+AND+all:agent)+OR+(all:meta-prompting)+OR+(ti:prompt+AND+ti:agent+AND+ti:LLM)"
           "&sortBy=submittedDate&sortOrder=descending&max_results=5")
    xml_text = fetch(url, headers={"Accept": "application/xml"})
    if not xml_text:
        return []

    papers = []
    for entry in re.finditer(r'<entry>(.*?)</entry>', xml_text, re.DOTALL):
        e = entry.group(1)
        title_m = re.search(r'<title>(.*?)</title>', e, re.DOTALL)
        link_m = re.search(r'<id>(.*?)</id>', e, re.DOTALL)
        summary_m = re.search(r'<summary>(.*?)</summary>', e, re.DOTALL)
        if title_m:
            title = re.sub(r'\s+', ' ', title_m.group(1).strip())
            link = link_m.group(1).strip() if link_m else ""
            summary = shorten(re.sub(r'\s+', ' ', summary_m.group(1).strip()), 150) if summary_m else ""
            papers.append({"t": title, "u": link, "s": summary})

    return papers


def collect_langchain():
    """Latest LangChain blog posts."""
    html = fetch("https://www.langchain.com/blog")
    if not html:
        return []

    posts = []
    # The blog cards have <a> overlay tags (empty) + <h2> headings nearby
    # Strategy: find all /blog/... links and pair them with nearby h2 text
    links = list(re.finditer(r'<a[^>]*href=["\'](/blog/[^"\']+)["\'][^>]*>', html))
    headings = list(re.finditer(r'<h2[^>]*>(.*?)</h2>', html, re.DOTALL | re.IGNORECASE))

    # Match links to next h2 heading (LangChain structure: link div, then card with h2)
    for link_match in links:
        url_path = link_match.group(1)
        link_pos = link_match.end()
        # Find the nearest h2 after this link
        for h2_match in headings:
            if h2_match.start() > link_pos and h2_match.start() < link_pos + 2000:
                title = re.sub(r'<[^>]+>', '', h2_match.group(1)).strip()
                if title and len(title) > 10 and not any(p['u'].endswith(url_path) for p in posts):
                    posts.append({"t": title, "u": f"https://www.langchain.com{url_path}"})
                break

    seen = set()
    result = []
    for p in posts:
        if p['t'] not in seen:
            seen.add(p['t'])
            result.append(p)
    return result[:5]


# --- Main ---

def main():
    print(f"📡 Collecte du briefing — {datetime.date.today()}", file=sys.stderr)

    data = {
        "date": datetime.date.today().isoformat(),
        "sources": {
            "hf_papers": collect_hf_papers(),
            "hermes_releases": collect_hermes_releases(),
            "hn_stories": collect_hn_ai_stories(),
            "openrouter_models": collect_openrouter_notable(),
            "anthropic_blog": collect_anthropic_blog(),
            "prompting_papers": collect_prompting_papers(),
            "langchain_blog": collect_langchain(),
        }
    }

    output = json.dumps(data, indent=1, ensure_ascii=False)
    size_kb = len(output) / 1024
    print(f"✅ Collecte terminée — {size_kb:.0f} KB", file=sys.stderr)
    print(output)


if __name__ == "__main__":
    main()
