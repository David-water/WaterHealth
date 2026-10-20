#!/usr/bin/env python3
"""Select an installed iPhone simulator without hard-coding device names or UUIDs."""
import json,re,sys
candidates=[]
for runtime,devices in json.load(sys.stdin).get('devices',{}).items():
    version=re.search(r'iOS-(\d+)-(\d+)',runtime)
    if not version or int(version[1])<17:continue
    for device in devices:
        if device.get('isAvailable') and device.get('name','').startswith('iPhone'):
            candidates.append(((int(version[1]),int(version[2])),device.get('state')=='Booted',device['udid']))
if not candidates:
    sys.exit('No iPhone simulator with iOS 17+ is installed. Install a runtime in Xcode Settings > Platforms, or set WATERHEALTH_SIMULATOR.')
print(max(candidates)[2])
