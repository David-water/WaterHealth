#!/usr/bin/env python3
"""Offline source-hygiene and documentation checks; Python standard library only."""
from pathlib import Path
import ast,re,urllib.parse
root=Path(__file__).resolve().parents[1]
ignore={'.git','.build','__pycache__'}
files=[p for p in root.rglob('*') if p.is_file() and not any(x in ignore for x in p.relative_to(root).parts)]
for name in ['README.md','README.zh-CN.md','LICENSE','NOTICE.md','CONTRIBUTING.md','SECURITY.md','Makefile']:
    assert (root/name).is_file(),name
for p in files:
    rel=p.relative_to(root)
    assert 'node_modules' not in rel.parts,rel
    assert p.suffix not in {'.mp4','.webm','.mov','.dmg','.zip','.ipa','.p12','.p8','.mobileprovision'},rel
    assert p.name!='.DS_Store',rel
    assert p.stat().st_size<=5*1024*1024,rel
    if p.suffix=='.py':ast.parse(p.read_text(),filename=str(rel))
    if p.suffix in {'.md','.swift','.py','.sh','.yml','.html','.js'}:
        body=p.read_text()
        assert not re.search(r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----',body),rel
        assert not re.search(r'gh[pousr]_[A-Za-z0-9_]{30,}',body),rel
        assert ('/Users/'+'water/') not in body,rel
    if p.suffix=='.md':
        refs=re.findall(r'!?\[[^\]]*\]\(([^)]+)\)',p.read_text())
        refs+=re.findall(r'(?:src|href)="([^"]+)"',p.read_text())
        for value in refs:
            value=urllib.parse.unquote(value.strip('<>').split('#')[0])
            if not value or re.match(r'^[a-z]+:',value):continue
            assert (p.parent/value).exists(),f'{rel}: missing {value}'
total=sum(p.stat().st_size for p in files)
assert total<=25*1024*1024,f'Source budget exceeded: {total}'
print(f'PASS: {len(files)} source/docs/assets files, {total/1024/1024:.2f} MiB; local links and hygiene.')
