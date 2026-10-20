#!/usr/bin/env python3
"""Check deployable static routes/assets and metadata, without committing binaries."""
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urlparse
import json,re
root=Path(__file__).resolve().parent
class Paths(HTMLParser):
    def handle_starttag(self,tag,attrs):
        for key,value in attrs:
            if key not in ['href','src'] or not value:continue
            url=urlparse(value)
            if url.scheme or url.netloc:continue
            path=url.path
            if not path:continue
            dest=root/path.lstrip('/')
            if path.endswith('/'):dest=dest/'index.html'
            assert dest.exists(),f'Missing website route: {value}'
for p in root.rglob('*.html'):Paths().feed(p.read_text())
meta=json.loads((root/'downloads/release.json').read_text())
assert meta['minimum_macos']=='14.0'
assert set(meta['architectures'])=={'arm64','x86_64'}
for item in meta['files']:
    assert re.fullmatch('[0-9a-f]{64}',item['sha256'])
    assert item['bytes']>0
    assert item['url'].startswith('https://github.com/David-water/WaterHealth/releases/download/')
for prefix,suffixes in [('iphone',['twin','reports','goals','nutrition','assistant','neural','muscle']),('ipad',['twin']),('mac',['twin'])]:
    for suffix in suffixes:assert (root/'assets'/f'{prefix}-{suffix}.webp').is_file()
print('PASS: static website routes, image states and external release metadata; installers are Release assets.')
