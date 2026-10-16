#!/usr/bin/env python3
"""
Left 4 Dead 2 - Full iOS IPA Assembler
Combines the compiled L4D2 iOS frontend, ProMotion configuration, touch overlays,
app icons, and the full ARM64 Source Engine runtime binaries (libengine, materialsystem,
vphysics, shaderapidx9, togl, SDL2.framework, extras_dir.vpk) into a Feather / TrollStore /
AltStore compliant ~34MB IPA with POSIX executable permissions.

Includes automatic binary optimizations for:
- Dialog cut-off fix (removes hardcoded 109pt vertical shift)
- Grey screen fix (switches view background from grayColor to blackColor)
- Default launch argument fix (pre-populates -game left4dead2 instead of -dev 2 -log)
"""

import sys
import shutil
import zipfile
import urllib.request
import struct
from pathlib import Path

ENGINE_RUNTIME_URL = "https://github.com/ksagameng2/source-engine/releases/download/1.0/source-engine.ipa"

def patch_launcher_binary(binary_path: Path):
    print("[*] Applying launcher optimizations (Centering dialog, black theme, L4D2 args)...")
    with open(binary_path, 'rb') as f:
        data = bytearray(f.read())

    # 1. Patch grayColor -> blackColor
    idx_gray = data.find(b'grayColor\x00')
    if idx_gray != -1:
        data[idx_gray:idx_gray+11] = b'blackColor\x00'
        print("    [+] Patched launcher theme: grayColor -> blackColor")

    # 2. Patch bl setTransform at 0x468c -> nop (0x1f2003d5)
    # This prevents the alert dialog from being shifted down by 109pt and cut off on modern iPhones/iPads!
    if len(data) > 0x4690:
        curr_instr = struct.unpack('<I', data[0x468c:0x4690])[0]
        if curr_instr == 0x94000305:
            data[0x468c:0x4690] = b'\x1f\x20\x03\xd5' # ARM64 NOP
            print("    [+] Patched launch dialog: Centered alert view (removed 109pt cut-off shift)")

    # 3. Patch default CFString from "-dev 2 -log" to "-game left4dead2 -fullscreen -noborder +fps_max 120"
    args_str = b'-game left4dead2 -fullscreen -noborder +fps_max 120\x00'
    if len(data) >= 0x5c50 + len(args_str):
        data[0x5c50:0x5c50+len(args_str)] = args_str

        # Update CFString at offset 33296
        cf_off = 33296
        if len(data) >= cf_off + 32:
            new_str_vm = 0x100000000 + 0x5c50
            new_len = len(args_str) - 1
            data[cf_off+16:cf_off+32] = struct.pack('<QQ', new_str_vm, new_len)
            print("    [+] Patched default arguments: -game left4dead2 -fullscreen -noborder +fps_max 120")

    with open(binary_path, 'wb') as f:
        f.write(data)

def generate_settings_bin(output_path: Path):
    magic = b'\x6f' # 111 (SETTINGS_MAGIC)
    args = b"-game left4dead2 -fullscreen -noborder +fps_max 120".ljust(1024, b'\x00')
    port = struct.pack('<I', 0)
    suffix = b"".ljust(32, b'\x00')
    ftpserver = struct.pack('<I', 0)
    # Alignment: magic(1) + args(1024) = 1025. Pad 3 bytes -> 1028.
    data = magic + args + b'\x00\x00\x00' + port + suffix + ftpserver
    with open(output_path, 'wb') as f:
        f.write(data)
    print(f"[+] Generated pre-configured settings.bin at: {output_path.name}")

def assemble_ipa(project_root: Path, output_ipa: Path):
    print("=" * 65)
    print(" Left 4 Dead 2 - Assembling Optimized iOS IPA")
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
            if member.startswith("Payload/hl2.app/"):
                rel_path = member[len("Payload/hl2.app/"):]
                if not rel_path or rel_path.startswith("_CodeSignature") or ".dSYM" in rel_path or ".DS_Store" in rel_path:
                    continue

                dest_file = app_dir / rel_path
                if member.endswith("/"):
                    dest_file.mkdir(parents=True, exist_ok=True)
                else:
                    dest_file.parent.mkdir(parents=True, exist_ok=True)
                    with zipf.open(member) as src_f, open(dest_file, 'wb') as dst_f:
                        shutil.copyfileobj(src_f, dst_f)

    # 3. Clean up non-signable framework clutter (causes Feather / zsign crashes)
    for dirty in app_dir.rglob("*.dSYM"):
        if dirty.is_dir():
            shutil.rmtree(dirty)
    for dirty in app_dir.rglob(".DS_Store"):
        if dirty.is_file():
            dirty.unlink()
    for dirty in app_dir.rglob("CMake"):
        if dirty.is_dir() and "Frameworks" in str(dirty):
            shutil.rmtree(dirty)

    # 4. Optimize and patch the launcher binary
    hl2_launcher = app_dir / "hl2_launcher"
    if hl2_launcher.exists():
        patch_launcher_binary(hl2_launcher)

    # 5. Inject customized Info.plist for Left 4 Dead 2
    custom_plist = project_root / "ios" / "Info.plist"
    if custom_plist.exists():
        print("[*] Injecting Feather-compatible Info.plist (120Hz ProMotion + File Sharing)...")
        shutil.copy2(custom_plist, app_dir / "Info.plist")

    # 6. Inject App Icons
    icons_dir = project_root / "ios" / "icons"
    if icons_dir.exists():
        print("[*] Injecting Left 4 Dead 2 app icons...")
        for icon_file in icons_dir.glob("*.png"):
            shutil.copy2(icon_file, app_dir / icon_file.name)
        for art in ["iTunesArtwork", "iTunesArtwork@2x"]:
            art_p = icons_dir / art
            if art_p.exists():
                shutil.copy2(art_p, app_dir / art)

    # 7. Inject pre-configured settings.bin and commandline.txt
    generate_settings_bin(app_dir / "settings.bin")

    # Inject verified gameinfo.txt for left4dead2 and hl2 in the app bundle
    export_dir = project_root / "export_for_ios"
    l4d2_gi = export_dir / "left4dead2" / "gameinfo.txt"
    hl2_gi = export_dir / "hl2" / "gameinfo.txt"

    if l4d2_gi.exists():
        app_l4d2_gi = app_dir / "left4dead2" / "gameinfo.txt"
        app_l4d2_gi.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(l4d2_gi, app_l4d2_gi)
        print("[+] Injected optimized left4dead2/gameinfo.txt inside app bundle")

    if hl2_gi.exists():
        app_hl2_gi = app_dir / "hl2" / "gameinfo.txt"
        app_hl2_gi.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(hl2_gi, app_hl2_gi)
        print("[+] Injected optimized hl2/gameinfo.txt inside app bundle")

    # Inject core startup graphics and debug textures directly into the app bundle
    for mod_name in ["left4dead2", "hl2"]:
        src_mat = export_dir / mod_name / "materials"
        if src_mat.exists():
            dst_mat = app_dir / mod_name / "materials"
            shutil.copytree(src_mat, dst_mat, dirs_exist_ok=True)
            print(f"[+] Injected core materials into app bundle ({mod_name}/materials)")

    # Also generate in export_for_ios so user can drop it into Documents
    if export_dir.exists():
        generate_settings_bin(export_dir / "settings.bin")

    cmdline_file = app_dir / "commandline.txt"
    with open(cmdline_file, 'w', encoding='utf-8') as f:
        f.write("-game left4dead2 -fullscreen -noborder +fps_max 120\n")

    # 8. Compress into output IPA with POSIX executable permissions (0o755)
    print(f"[*] Packaging into Feather-compatible IPA: {output_ipa.name}...")
    if output_ipa.exists():
        output_ipa.unlink()

    binary_names = {
        'hl2_launcher', 'SDL2', 'libEGL', 'libGLESv2'
    }

    with zipfile.ZipFile(output_ipa, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for file_path in staging_dir.rglob('*'):
            rel = file_path.relative_to(staging_dir)
            rel_str = str(rel).replace('\\', '/')

            if file_path.is_dir():
                zinfo = zipfile.ZipInfo(rel_str + '/')
                zinfo.external_attr = (0o755 << 16) | 0o40000
                zipf.writestr(zinfo, '')
            else:
                with open(file_path, 'rb') as f:
                    data = f.read()

                zinfo = zipfile.ZipInfo(rel_str)
                is_executable = (
                    file_path.name in binary_names or
                    file_path.suffix == '.dylib' or
                    ('Frameworks' in rel_str and file_path.suffix not in ('.plist', '.txt', '.metallib', '.h', '.cmake'))
                )

                if is_executable:
                    zinfo.external_attr = 0o755 << 16
                else:
                    zinfo.external_attr = 0o644 << 16

                zipf.writestr(zinfo, data)

    # Clean up staging
    shutil.rmtree(staging_dir)

    size_mb = output_ipa.stat().st_size / (1024 * 1024)
    print("\n" + "=" * 65)
    print(f" [+] COMPLETE OPTIMIZED L4D2 IPA ASSEMBLED!")
    print(f" Output: {output_ipa} ({size_mb:.2f} MB)")
    print("=" * 65)
    return True

if __name__ == "__main__":
    root = Path(__file__).resolve().parent.parent
    out = root / "Left4Dead2.ipa" if len(sys.argv) <= 1 else Path(sys.argv[1]).resolve()
    assemble_ipa(root, out)
