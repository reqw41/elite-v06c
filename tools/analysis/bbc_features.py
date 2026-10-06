#!/usr/bin/env python3
"""Таблица возможностей версий Elite с elite.bbcelite.com → markdown.
Запуск: curl -sL -A Mozilla/5.0 https://elite.bbcelite.com/compare/feature_comparison.html -o work/bbc/features.html
        python3 -I tools/analysis/bbc_features.py work/bbc/features.html > docs/research/bbc_features.md
"""
import re, html, sys
s = open(sys.argv[1], encoding='utf-8', errors='replace').read()
t = re.search(r'<table.*?</table>', s, re.S).group(0)
print('# Сравнение версий Elite на 6502\n\nИсточник: https://elite.bbcelite.com/compare/feature_comparison.html (Mark Moxon). Таблица извлечена скриптом\n`tools/analysis/bbc_features.py`, без правок.\n')
for i, tr in enumerate(re.findall(r'<tr.*?</tr>', t, re.S)):
    c = [re.sub(r'\s+', ' ', html.unescape(re.sub(r'<[^>]+>', '', x))).strip() for x in re.findall(r'<t[hd][^>]*>(.*?)</t[hd]>', tr, re.S)]
    print('| ' + ' | '.join(c) + ' |')
    if i == 0: print('|' + '---|' * len(c))
