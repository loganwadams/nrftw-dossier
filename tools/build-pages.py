#!/usr/bin/env python3
"""Deploy-time step (see .github/workflows/pages.yml): write a real HTML file for each clean
section URL so GitHub Pages answers /trove, /vendors, /cerim-builder and /media with HTTP 200.

Without these, those URLs had no file behind them: Pages served 404.html, whose script bounced
the visitor to /?p=... and the app restored the path. Fine for people, but search engines saw a
404 and refused to index anything but the homepage. GitHub Pages serves `trove.html` for a
request to `/trove` (no trailing slash, no directory), so the URL in the address bar is still the
clean one, the router's CLEAN_PATHS still match, and relative asset paths still resolve to the
site root. Each copy also gets its own <title>, description, canonical and og:url so the crawler
sees section-specific metadata before any script runs.

Run from the repo root. Outputs are build products, not source - they're .gitignored.
"""
import re, sys, html

SITE = 'https://wickeddossier.com'
PAGES = {
    'trove': ('Trove — No Rest for the Wicked Item Database | Wicked Dossier',
              'Every No Rest for the Wicked item in one place: weapons, armor, shields, runes, gems, ingredients and crafting recipes, with stats, sources, crafting and upgrade materials.'),
    'vendors': ('Vendors — No Rest for the Wicked Merchants & Stock | Wicked Dossier',
                'Every vendor in No Rest for the Wicked, what they sell, their prices and where to find them in Sacrament and Marin Village.'),
    'cerim-builder': ('Cerim Builder — No Rest for the Wicked Build Planner | Wicked Dossier',
                      'Plan a No Rest for the Wicked build: pick weapons, armor, runes, gems and enchantments, see your stats and requirements, rate the build and share it with a link.'),
    'media': ('Media — No Rest for the Wicked Trailers & Videos | Wicked Dossier',
              'Official No Rest for the Wicked trailers, gameplay reveals and developer videos from Moon Studios.'),
}

src = open('index.html', encoding='utf-8').read()

def sub1(s, pattern, repl):
    s2, n = re.subn(pattern, repl, s, count=1)
    if n != 1:
        sys.exit('build-pages: pattern not found: ' + pattern)
    return s2

for slug, (title, desc) in PAGES.items():
    t, d = html.escape(title, quote=True), html.escape(desc, quote=True)
    url = f'{SITE}/{slug}'
    out = src
    out = sub1(out, r'<title>[^<]*</title>', f'<title>{t}</title>')
    out = sub1(out, r'<meta name="description" content="[^"]*">', f'<meta name="description" content="{d}">')
    out = sub1(out, r'<link rel="canonical" href="[^"]*">', f'<link rel="canonical" href="{url}">')
    out = sub1(out, r'<meta property="og:url" content="[^"]*">', f'<meta property="og:url" content="{url}">')
    out = sub1(out, r'<meta property="og:title" content="[^"]*">', f'<meta property="og:title" content="{t}">')
    out = sub1(out, r'<meta property="og:description" content="[^"]*">', f'<meta property="og:description" content="{d}">')
    out = sub1(out, r'<meta name="twitter:title" content="[^"]*">', f'<meta name="twitter:title" content="{t}">')
    out = sub1(out, r'<meta name="twitter:description" content="[^"]*">', f'<meta name="twitter:description" content="{d}">')
    open(f'{slug}.html', 'w', encoding='utf-8').write(out)
    print(f'wrote {slug}.html')
