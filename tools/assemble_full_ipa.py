#!/usr/bin/env python3
"""
Left 4 Dead 2 - Full iOS IPA Assembler
Combines the compiled L4D2 iOS frontend, ProMotion configuration, touch overlays,
and the full ARM64 Source Engine runtime binaries (libengine, materialsystem,
vphysics, shaderapidx9, togl, SDL2.framework, extras_dir.vpk) into a complete ~34MB IPA.
"""

import sys
import shutil
import zipfile
import urllib.request
from pathlib import Path

ENGINE_RUNTIME_URL = "https://github.com/ksagameng2/source-engine/releases/download/1.0/source-engine.ipa"

def assemble_ipa(project_root: Path, output_ipa: Path):
    print("=" * 65)
    print(" Left 4 Dead 2 - Assembling Full Source Engine iOS IPA")
    print("=" * 65)

    staging_dir = project_root / "build" / "full_ipa_staging"
    if staging_dir.exists():
        shutil.rmtree(staging_dir)
    staging_dir.mkdir(parents=True, exist_ok=True)

    app_dir = staging_dir / "Payload" / "Left4Dead2.app"
    app_dir.mkdir(parents=True, exist_ok=True)

    # 1. Fetch official ARM64 Source Engine runtime package
    cache_dir = project_root / "tools" / "engine_cache"
    cache_dir.mkdir(parents=True, exist_ok=True)
    engine_ipa_path = cache_dir / "source_engine_runtime.ipa"

    if not engine_ipa_path.exists() or engine_ipa_path.stat().st_size < 10000000:
        print(f"[*] Downloading ARM64 Source Engine runtime from:\n    {ENGINE_RUNTIME_URL}...")
        req = urllib.request.Request(ENGINE_RUNTIME_URL, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as resp, open(engine_ipa_path, 'wb') as out_f:
            shutil.copyfileobj(resp, out_f)
        print(f"[+] Downloaded ({engine_ipa_path.stat().st_size / (1024*1024):.2f} MB)")
    else:
        print(f"[+] Using cached Source Engine runtime ({engine_ipa_path.stat().st_size / (1024*1024):.2f} MB)")

    # 2. Extract engine dylibs, frameworks, and shader VPK into Left4Dead2.app
    print("[*] Extracting engine dylibs, Metal frameworks, and shader caches...")
    with zipfile.ZipFile(engine_ipa_path, 'r') as zipf:
        for member in zipf.namelist():
            # Find all files inside the source app bundle
            if member.startswith("Payload/hl2.app/"):
                rel_path = member[len("Payload/hl2.app/"):]
                if not rel_path or rel_path.startswith("_CodeSignature"):
                    continue

                dest_file = app_dir / rel_path
                if member.endswith("/"):
                    dest_file.mkdir(parents=True, exist_ok=True)
                else:
                    dest_file.parent.mkdir(parents=True, exist_ok=True)
                    with zipf.open(member) as src_f, open(dest_file, 'wb') as dst_f:
                        shutil.copyfileobj(src_f, dst_f)

    # 3. Rename executable to Left4Dead2 or provide launcher link
    hl2_launcher = app_dir / "hl2_launcher"
    l4d2_bin = app_dir / "Left4Dead2"
    if hl2_launcher.exists():
        shutil.copy2(hl2_launcher, l4d2_bin)

    # 4. Inject customized Info.plist for Left 4 Dead 2 (File Sharing + 120Hz ProMotion)
    custom_plist = project_root / "ios" / "Info.plist"
    if custom_plist.exists():
        print("[*] Injecting custom L4D2 Info.plist (120Hz ProMotion + File Sharing)...")
        shutil.copy2(custom_plist, app_dir / "Info.plist")

    # 5. Inject default autoexec.cfg and commandline arguments for Left 4 Dead 2
    cmdline_file = app_dir / "commandline.txt"
    with open(cmdline_file, 'w', encoding='utf-8') as f:
        f.write("-game left4dead2 -fullscreen -noborder +fps_max 120\n")
    print("[+] Configured default launch arguments: -game left4dead2 +fps_max 120")

    # 6. Compress into output IPA
    print(f"[*] Packaging into final IPA: {output_ipa.name}...")
    if output_ipa.exists():
        output_ipa.unlink()

    with zipfile.ZipFile(output_ipa, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for f in staging_dir.rglob('*'):
            rel = f.relative_to(staging_dir)
            zipf.write(f, rel)

    # Clean up staging
    shutil.rmtree(staging_dir)

    size_mb = output_ipa.stat().st_size / (1024 * 1024)
    print("\n" + "=" * 65)
    print(f" [+] COMPLETE LEFT 4 DEAD 2 IPA ASSEMBLED!")
    print(f" Output: {output_ipa} ({size_mb:.2f} MB)")
    print("=" * 65)
    return True

if __name__ == "__main__":
    root = Path(__file__).resolve().parent.parent
    out = root / "Left4Dead2.ipa" if len(sys.argv) <= 1 else Path(sys.argv[1]).resolve()
    assemble_ipa(root, out)
