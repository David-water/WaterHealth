#!/usr/bin/env python3
"""Package the macOS-only universal binary, preserving executable bits and signatures."""
from pathlib import Path
import argparse, hashlib, json, os, plistlib, re, shutil, subprocess, tempfile

ROOT = Path(__file__).resolve().parents[1]
args = argparse.ArgumentParser()
args.add_argument('--build-dir', default=str(ROOT / '.build/macos'))
opt = args.parse_args()
source = Path(opt.build_dir) / 'Build/Products/Release/WaterHealth.app'
info = plistlib.loads((source / 'Contents/Info.plist').read_bytes())
assert info['CFBundleSupportedPlatforms'] == ['MacOSX'], 'Refusing to distribute an iOS app as a Mac app'
assert info['LSMinimumSystemVersion'] == '14.0'
binary = source / 'Contents/MacOS/WaterHealth'
archs = subprocess.check_output(['lipo', '-archs', str(binary)], text=True).strip().split()
assert set(archs) == {'arm64', 'x86_64'}, archs
out = ROOT / '.build/release'
app = out / 'macOS/WaterHealth.app'
app.parent.mkdir(parents=True, exist_ok=True)
if app.exists(): shutil.rmtree(app)
subprocess.run(['ditto', str(source), str(app)], check=True)
identity = os.environ.get('WATERHEALTH_SIGN_IDENTITY', '-')
cmd = ['codesign', '--force', '--sign', identity, '--options', 'runtime', '--entitlements', str(ROOT / 'macos/WaterHealth.entitlements')]
if identity != '-': cmd.append('--timestamp')
subprocess.run(cmd + [str(app)], check=True)
subprocess.run(['codesign', '--verify', '--deep', '--strict', str(app)], check=True)
readme = '''WaterHealth Mac 体验版 1.0.0

适用于 macOS 14 或更新版本；支持 Apple 芯片和 Intel。无需安装 Xcode。

安装：打开磁盘映像，将 WaterHealth.app 拖入「应用程序」，再从「应用程序」打开。
当前体验包采用本地 ad-hoc 签名，没有 Developer ID 签名和 Apple 公证。
如果首次打开被系统阻止：先尝试打开一次，再进入「系统设置 → 隐私与安全性」，
找到 WaterHealth 的提示并选择「仍要打开」，根据系统提示确认。无需关闭 Gatekeeper。
仅从 WaterHealth 官网下载，核对 SHA-256 校验值后再操作。

旧的 iOS 模拟器 WaterHealth.app 不支持 macOS 直接启动；请使用本包的 Mac 版本。
首次启动可创建个人档案，也可以选择「体验演示档案」。健康数据保存在本机。
Mac 当前不提供 Apple 健康同步和本地目标通知；其他核心记录功能正常使用。
演示数据、年龄和风险读数不作为诊断；营养药房为模拟订单，无支付或发货。
'''
(out / 'macOS/首次打开说明.txt').write_text(readme)
with tempfile.TemporaryDirectory(prefix='waterhealth-dmg-') as task_tmp:
    staging = Path(task_tmp) / 'WaterHealth'
    staging.mkdir()
    subprocess.run(['ditto', str(app), str(staging / 'WaterHealth.app')], check=True)
    (staging / 'Applications').symlink_to('/Applications')
    (staging / '首次打开说明.txt').write_text(readme)
    dmg = out / 'WaterHealth-macOS.dmg'
    subprocess.run(['hdiutil', 'create', '-volname', 'WaterHealth', '-srcfolder', str(staging), '-format', 'UDZO', '-ov', str(dmg)], check=True)
zipfile = out / 'WaterHealth-macOS.zip'
if zipfile.exists(): zipfile.unlink()
subprocess.run(['ditto', '-c', '-k', '--sequesterRsrc', '--keepParent', str(app.parent), str(zipfile)], check=True)
files = []
for path in [dmg, zipfile]:
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    path.with_suffix(path.suffix + '.sha256').write_text(f'{digest}  {path.name}\n')
    files.append({'name': path.name, 'bytes': path.stat().st_size, 'sha256': digest})
metadata = {'version': '1.0.0', 'minimum_macos': '14.0', 'architectures': archs, 'signing': 'ad-hoc' if identity == '-' else 'Developer ID (notarization must be completed separately)', 'notarized': False, 'files': files}
(out / 'release.json').write_text(json.dumps(metadata, indent=2, ensure_ascii=False))
print(json.dumps(metadata, indent=2, ensure_ascii=False))
