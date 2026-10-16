#!/usr/bin/env python3
"""
Left 4 Dead 2 - Steam Asset Downloader & Ingestion Tool for iOS Port
Automates downloading clean PC Steam content (App ID 550) via steamcmd
and prepares the staged 'export_for_ios' directory for direct transfer.
"""

import os
import sys
import subprocess
import shutil
import urllib.request
import zipfile
from pathlib import Path

L4D2_APP_ID = 550
STEAMCMD_URL_WIN = "https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip"

def find_or_install_steamcmd(tools_dir: Path) -> Path:
    # Check if steamcmd is in PATH
    path_steamcmd = shutil.which("steamcmd")
    if path_steamcmd:
        print(f"[+] Found steamcmd in PATH: {path_steamcmd}")
        return Path(path_steamcmd)

    # Check local tools directory
    local_steamcmd = tools_dir / "steamcmd" / ("steamcmd.exe" if sys.platform == "win32" else "steamcmd.sh")
    if local_steamcmd.exists():
        print(f"[+] Found local steamcmd: {local_steamcmd}")
        return local_steamcmd

    # Auto-download portable steamcmd on Windows
    if sys.platform == "win32":
        print("[*] steamcmd not found. Downloading portable steamcmd for Windows...")
        steamcmd_dir = tools_dir / "steamcmd"
        steamcmd_dir.mkdir(parents=True, exist_ok=True)
        zip_path = steamcmd_dir / "steamcmd.zip"
        
        print(f"[*] Downloading {STEAMCMD_URL_WIN}...")
        urllib.request.urlretrieve(STEAMCMD_URL_WIN, zip_path)
        
        print("[*] Extracting steamcmd...")
        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            zip_ref.extractall(steamcmd_dir)
        zip_path.unlink()
        
        print(f"[+] steamcmd installed to: {local_steamcmd}")
        return local_steamcmd
    else:
        print("[!] Please install steamcmd using your package manager (e.g. brew install steamcmd or apt install steamcmd).")
        sys.exit(1)

def run_download(steamcmd_path: Path, output_dir: Path, username: str):
    print(f"\n[*] Starting SteamCMD download for Left 4 Dead 2 (App ID: {L4D2_APP_ID})...")
    print(f"[*] Destination: {output_dir}")
    print("[!] NOTE: You may be prompted for your Steam password and Steam Guard code in the terminal.\n")

    cmd = [
        str(steamcmd_path),
        "+force_install_dir", str(output_dir),
        "+login", username,
        "+app_update", str(L4D2_APP_ID), "validate",
        "+quit"
    ]

    result = subprocess.run(cmd)
    if result.returncode != 0:
        print(f"\n[!] SteamCMD exited with code {result.returncode}")
        print("[!] If you entered the wrong password or canceled 2FA, re-run this script.")
        return False
    return True

def prepare_ios_staging(raw_steam_dir: Path, staging_dir: Path):
    print(f"\n[*] Staging game assets for iOS in: {staging_dir}")
    staging_dir.mkdir(parents=True, exist_ok=True)

    # Folders required and recommended by the engine on iOS
    folders_to_copy = ["left4dead2", "hl2", "left4dead2_dlc1", "left4dead2_dlc2", "left4dead2_dlc3", "update"]

    for folder in folders_to_copy:
        src = raw_steam_dir / folder
        dst = staging_dir / folder
        if not src.exists():
            continue

        print(f"[*] Staging {folder}/...")
        if dst.exists():
            shutil.rmtree(dst)
        shutil.copytree(src, dst, ignore=shutil.ignore_patterns("*.exe", "*.dll", "*.pdb", "DirectX*"))
        print(f"[+] {folder}/ staged successfully.")

    # 1. Ensure fallback hl2/gameinfo.txt exists to prevent 'gameinfo.txt doesn't exist in subdirectory hl2' error
    hl2_gameinfo = staging_dir / "hl2" / "gameinfo.txt"
    if not hl2_gameinfo.exists():
        hl2_gameinfo.parent.mkdir(parents=True, exist_ok=True)
        with open(hl2_gameinfo, 'w', encoding='utf-8') as f:
            f.write('"GameInfo"\n{\n\tgame\t\t"Left 4 Dead 2"\n\ttitle\t\t"LEFT 4 DEAD 2"\n\ttype\t\tmultiplayer_only\n\n\tFileSystem\n\t{\n\t\tSteamAppId\t\t550\n\t\tSearchPaths\n\t\t{\n\t\t\tGame\t\t|gameinfo_path|../left4dead2\n\t\t\tGame\t\t|gameinfo_path|.\n\t\t\tGame\t\tleft4dead2\n\t\t\tGame\t\thl2\n\t\t}\n\t}\n}\n')
        print("[+] Generated fallback hl2/gameinfo.txt (prevents missing gameinfo error)")

    print("\n" + "=" * 60)
    print(" [✓] Left 4 Dead 2 iOS Assets Ready for Transfer!")
    print("=" * 60)
    print(f"Staged Assets Location: {staging_dir}\n")
    print("HOW TO TRANSFER TO IPHONE / IPAD:")
    print("1. Connect device to PC via USB cable.")
    print("2. Open iTunes / Apple Devices / Finder.")
    print("3. Click your device -> 'File Sharing' -> Select 'L4D2 iOS'.")
    print(f"4. Drag and drop the folders from:\n   {staging_dir}")
    print("   directly into the app documents.\n")
    print("Alternatively, use the iOS 'Files' app on your device:")
    print("   'On My iPhone' -> 'L4D2 iOS' -> Paste 'left4dead2' and 'hl2'.")
    print("=" * 60)

def main():
    tools_dir = Path(__file__).resolve().parent
    project_root = tools_dir.parent
    raw_download_dir = project_root / "raw_steam_l4d2"
    staging_dir = project_root / "export_for_ios"

    print("=" * 60)
    print(" Left 4 Dead 2 - Steam Asset Ingestion for iOS Port")
    print("=" * 60)

    # 1. Check for local installed Steam library paths
    common_local_paths = [
        Path(r"F:\SteamLibrary\steamapps\common\Left 4 Dead 2"),
        Path(r"D:\SteamLibrary\steamapps\common\Left 4 Dead 2"),
        Path(r"E:\SteamLibrary\steamapps\common\Left 4 Dead 2"),
        Path(r"C:\Program Files (x86)\Steam\steamapps\common\Left 4 Dead 2"),
        Path(r"C:\SteamLibrary\steamapps\common\Left 4 Dead 2"),
    ]

    for local_path in common_local_paths:
        if (local_path / "left4dead2" / "gameinfo.txt").exists():
            print(f"\n[+] Detected existing local installation at: {local_path}")
            ans = input("Do you want to stage assets directly from this local install? [Y/n]: ").strip().lower()
            if ans != 'n':
                prepare_ios_staging(local_path, staging_dir)
                return

    # 2. Check if user already has an existing SteamCMD download
    if (raw_download_dir / "left4dead2" / "gameinfo.txt").exists():
        print(f"[+] Found existing SteamCMD download at: {raw_download_dir}")
        ans = input("Do you want to re-download or proceed to stage assets? [stage/download]: ").strip().lower()
        if ans != "download":
            prepare_ios_staging(raw_download_dir, staging_dir)
            return

    steamcmd = find_or_install_steamcmd(tools_dir)

    username = input("\nEnter your Steam Username (owning Left 4 Dead 2): ").strip()
    if not username:
        print("[!] Steam username cannot be empty.")
        sys.exit(1)

    success = run_download(steamcmd, raw_download_dir, username)
    if success:
        prepare_ios_staging(raw_download_dir, staging_dir)

if __name__ == "__main__":
    main()
