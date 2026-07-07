import sys
sys.path.insert(0, '.')
from crawler.base.base_crawler import BaseCrawler
from bs4 import BeautifulSoup

class DebugCrawler(BaseCrawler):
    pass

s = DebugCrawler()
html = s.get('https://search.suning.com/emall/searchV1Product.do?keyword=手机&pg=01')

if html is None:
    print('Failed to fetch page')
    exit()

soup = BeautifulSoup(html, 'html.parser')

# Find li elements with class containing 'product'
lis = soup.find_all('li')
print(f'Total li tags: {len(lis)}')
for li in lis[:5]:
    classes = li.get('class', [])
    text = li.get_text(strip=True)[:80]
    print(f'  class={classes} text={text}')

# Find price elements
for selector in ['.def-price', '.price', '[class*=price]', '[class*=Price]', 'em', 'strong', 'span', 'i']:
    els = soup.select(selector)
    for el in els[:2]:
        txt = el.get_text(strip=True)
        if txt and ('¥' in txt or '&yen;' in txt or any(c.isdigit() for c in txt[:3])):
            classes = el.get('class', [])
            print(f'  PRICE found: selector={selector} class={classes} text={txt[:30]}')

# Save HTML sample for inspection
with open('suning_debug.html', 'w', encoding='utf-8') as f:
    f.write(html[:5000])
print('Wrote suning_debug.html (5000 bytes)')
