#!/usr/bin/env python3
"""Rebuild the checked-in Xcode project without a third-party generator."""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parents[1]
IOS = ROOT / 'ios'
PROJECT = IOS / 'WaterHealth.xcodeproj'
PROJECT.mkdir(exist_ok=True)

def uid(value): return hashlib.sha1(value.encode()).hexdigest().upper()[:24]
def q(value): return json.dumps(str(value), ensure_ascii=False)
objects = []
def obj(key, text):
    identity = uid(key)
    objects.append(f'\t\t{identity} = {{ {text} }};')
    return identity
def refs(ids): return '(' + ', '.join(ids) + ')'

sources = sorted((IOS/'WaterHealth').rglob('*.swift'))
tests = sorted((IOS/'WaterHealthTests').rglob('*.swift'))
uitests = sorted((IOS/'WaterHealthUITests').rglob('*.swift'))
source_refs = {}
for path in sources + tests + uitests:
    rel = path.relative_to(IOS).as_posix()
    source_refs[path] = obj('file:'+rel, f'isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {q(rel)}; sourceTree = SOURCE_ROOT;')
asset = obj('file:assets', 'isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = WaterHealth/Assets.xcassets; sourceTree = SOURCE_ROOT;')
privacy = obj('file:privacy', 'isa = PBXFileReference; lastKnownFileType = text.xml; path = WaterHealth/PrivacyInfo.xcprivacy; sourceTree = SOURCE_ROOT;')
info = obj('file:info', 'isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = WaterHealth/Info.plist; sourceTree = SOURCE_ROOT;')
entitlements = obj('file:entitlements', 'isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = WaterHealth/WaterHealth.entitlements; sourceTree = SOURCE_ROOT;')
products = []
target_ids = []
config = {}
project_settings = {'CLANG_ENABLE_MODULES':'YES','SDKROOT':'iphoneos','IPHONEOS_DEPLOYMENT_TARGET':'17.0','SWIFT_VERSION':'5.0','ENABLE_USER_SCRIPT_SANDBOXING':'YES','SWIFT_STRICT_CONCURRENCY':'minimal','CODE_SIGN_STYLE':'Automatic'}
def settings(mapping): return '{ ' + ' '.join(f'{k} = {q(v)};' for k,v in mapping.items()) + ' }'
for mode in ['Debug','Release']:
    config[mode] = obj('project-config:'+mode, f'isa = XCBuildConfiguration; buildSettings = {settings(project_settings | {"SWIFT_OPTIMIZATION_LEVEL": "-Onone" if mode == "Debug" else "-O", "ENABLE_TESTABILITY": "YES" if mode == "Debug" else "NO"})}; name = {mode};')
project_configs = obj('project-config-list', f'isa = XCConfigurationList; buildConfigurations = {refs(config.values())}; defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')

for name, files, ext, typ in [('WaterHealth',sources,'app','com.apple.product-type.application'),('WaterHealthMac',sources,'app','com.apple.product-type.application'),('WaterHealthTests',tests,'xctest','com.apple.product-type.bundle.unit-test'),('WaterHealthUITests',uitests,'xctest','com.apple.product-type.bundle.ui-testing')]:
    product = obj('product:'+name, f'isa = PBXFileReference; explicitFileType = {"wrapper.application" if ext == "app" else "wrapper.cfbundle"}; includeInIndex = 0; path = {"WaterHealth" if name == "WaterHealthMac" else name}.{ext}; sourceTree = BUILT_PRODUCTS_DIR;')
    products.append(product)
    build_files = [obj('build:'+name+':'+p.relative_to(IOS).as_posix(), f'isa = PBXBuildFile; fileRef = {source_refs[p]};') for p in files]
    source_phase = obj('sources:'+name, f'isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = {refs(build_files)}; runOnlyForDeploymentPostprocessing = 0;')
    framework_phase = obj('frameworks:'+name, 'isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;')
    resource_files = []
    if ext == 'app':
        resource_files = [obj('build:assets:'+name, f'isa = PBXBuildFile; fileRef = {asset};'),obj('build:privacy:'+name,f'isa = PBXBuildFile; fileRef = {privacy};')]
    resource_phase = obj('resources:'+name, f'isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = {refs(resource_files)}; runOnlyForDeploymentPostprocessing = 0;')
    target_settings = {'PRODUCT_NAME':'$(TARGET_NAME)','PRODUCT_BUNDLE_IDENTIFIER':'com.waterhealth.' + ('app' if ext == 'app' else name.lower()),'TARGETED_DEVICE_FAMILY':'1,2','SUPPORTED_PLATFORMS':'iphoneos iphonesimulator','GENERATE_INFOPLIST_FILE':'YES','SWIFT_EMIT_LOC_STRINGS':'YES','LD_RUNPATH_SEARCH_PATHS':'$(inherited) @executable_path/Frameworks'}
    if ext == 'app': target_settings |= {'INFOPLIST_FILE':'WaterHealth/Info.plist','GENERATE_INFOPLIST_FILE':'NO','ASSETCATALOG_COMPILER_APPICON_NAME':'AppIcon','CODE_SIGN_ENTITLEMENTS':'WaterHealth/WaterHealth.entitlements','MARKETING_VERSION':'1.0.0','CURRENT_PROJECT_VERSION':'1','ENABLE_PREVIEWS':'YES'}
    if name == 'WaterHealthMac':
        target_settings |= {'SDKROOT':'macosx','SUPPORTED_PLATFORMS':'macosx','MACOSX_DEPLOYMENT_TARGET':'14.0','PRODUCT_NAME':'WaterHealth','PRODUCT_BUNDLE_IDENTIFIER':'com.waterhealth.mac','INFOPLIST_FILE':'../macos/Info.plist','CODE_SIGN_ENTITLEMENTS':'../macos/WaterHealth.entitlements','ENABLE_HARDENED_RUNTIME':'YES','COMBINE_HIDPI_IMAGES':'YES','ASSETCATALOG_COMPILER_APPICON_NAME':'MacAppIcon','LD_RUNPATH_SEARCH_PATHS':'$(inherited) @executable_path/../Frameworks'}
    elif name == 'WaterHealthTests': target_settings |= {'TEST_HOST':'$(BUILT_PRODUCTS_DIR)/WaterHealth.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/WaterHealth','BUNDLE_LOADER':'$(TEST_HOST)'}
    else: target_settings |= {'TEST_TARGET_NAME':'WaterHealth'}
    configurations = [obj('config:'+name+':'+mode, f'isa = XCBuildConfiguration; buildSettings = {settings(target_settings)}; name = {mode};') for mode in ['Debug','Release']]
    configs = obj('config-list:'+name, f'isa = XCConfigurationList; buildConfigurations = {refs(configurations)}; defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
    deps = []
    if ext != 'app':
        proxy = obj('proxy:'+name, f'isa = PBXContainerItemProxy; containerPortal = {uid("project")}; proxyType = 1; remoteGlobalIDString = {uid("target:WaterHealth")}; remoteInfo = WaterHealth;')
        deps = [obj('dep:'+name, f'isa = PBXTargetDependency; target = {uid("target:WaterHealth")}; targetProxy = {proxy};')]
    target_ids.append(obj('target:'+name, f'isa = PBXNativeTarget; buildConfigurationList = {configs}; buildPhases = {refs([source_phase,framework_phase,resource_phase])}; buildRules = (); dependencies = {refs(deps)}; name = {name}; productName = {name}; productReference = {product}; productType = {q(typ)};'))

product_group = obj('products', f'isa = PBXGroup; children = {refs(products)}; name = Products; sourceTree = "<group>";')
main = obj('main', f'isa = PBXGroup; children = {refs(list(source_refs.values())+[asset,privacy,info,entitlements,product_group])}; sourceTree = "<group>";')
obj('project', f'isa = PBXProject; attributes = {{ BuildIndependentTargetsInParallel = YES; LastUpgradeCheck = 2700; TargetAttributes = {{ {uid("target:WaterHealth")} = {{ CreatedOnToolsVersion = 27.0; SystemCapabilities = {{ com.apple.HealthKit = {{ enabled = 1; }}; }}; }}; }}; }}; buildConfigurationList = {project_configs}; compatibilityVersion = "Xcode 14.0"; developmentRegion = "zh-Hans"; hasScannedForEncodings = 0; knownRegions = ("zh-Hans", en, Base); mainGroup = {main}; productRefGroup = {product_group}; projectDirPath = ""; projectRoot = ""; targets = {refs(target_ids)};')
(PROJECT/'project.pbxproj').write_text('// !$*UTF8*$!\n{\n\tarchiveVersion = 1;\n\tclasses = {};\n\tobjectVersion = 56;\n\tobjects = {\n'+'\n'.join(objects)+'\n\t};\n\trootObject = '+uid('project')+';\n}\n')
schemes = PROJECT/'xcshareddata'/'xcschemes'
schemes.mkdir(parents=True, exist_ok=True)
def build_ref(name,ext): return f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{uid("target:"+name)}" BuildableName="{name}.{ext}" BlueprintName="{name}" ReferencedContainer="container:WaterHealth.xcodeproj"/>'
(schemes/'WaterHealth.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2700" version="1.3">
 <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{build_ref('WaterHealth','app')}</BuildActionEntry></BuildActionEntries></BuildAction>
 <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables><TestableReference skipped="NO">{build_ref('WaterHealthTests','xctest')}</TestableReference><TestableReference skipped="NO">{build_ref('WaterHealthUITests','xctest')}</TestableReference></Testables></TestAction>
 <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{build_ref('WaterHealth','app')}</BuildableProductRunnable></LaunchAction>
 <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{build_ref('WaterHealth','app')}</BuildableProductRunnable></ProfileAction>
 <AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>''')

print(PROJECT)

(schemes/'WaterHealthMac.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2700" version="1.3">
 <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{uid("target:WaterHealthMac")}" BuildableName="WaterHealth.app" BlueprintName="WaterHealthMac" ReferencedContainer="container:WaterHealth.xcodeproj"/></BuildActionEntry></BuildActionEntries></BuildAction>
 <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal"><BuildableProductRunnable runnableDebuggingMode="0"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{uid("target:WaterHealthMac")}" BuildableName="WaterHealth.app" BlueprintName="WaterHealthMac" ReferencedContainer="container:WaterHealth.xcodeproj"/></BuildableProductRunnable></LaunchAction>
 <AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>''')
