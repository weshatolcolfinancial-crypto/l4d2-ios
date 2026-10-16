#!/usr/bin/env python3
"""
Left 4 Dead 2 - Asset Verification Tool
Verifies that a directory contains all necessary PC game files before transferring to iOS.
"""

import sys
from pathlib import Path

CRITICAL_FILES = [
    "left4dead2/gameinfo.txt",
    "left4dead2/pak01_dir.vpk"
]

RECOMMENDED_FILES = [
    "left4dead2/left4dead2_dir.vpk",
    "hl2/hl2_dir.vpk",
    "left4dead2/sound.cache"
]

def verify_directory(target_path: Path) -> bool:
    print("=" * 60)
    print(f" Checking Left 4 Dead 2 Asset Directory: {target_path}")
    print("=" * 60)

    if not target_path.exists():
        print(f"[!] ERROR: Target path does not exist: {target_path}")
        return False

    missing_critical = []
    found_critical = []
    missing_recommended = []
    found_recommended = []

    for rel in CRITICAL_FILES:
        full = target_path / rel
        if full.exists():
            size_mb = full.stat().st_size / (1024 * 1024)
            found_critical.append((rel, size_mb))
        else:
            missing_critical.append(rel)

    for rel in RECOMMENDED_FILES:
        full = target_path / rel
        if full.exists():
            size_mb = full.stat().st_size / (1024 * 1024)
            found_recommended.append((rel, size_mb))
        else:
            missing_recommended.append(rel)

    print("\n--- Critical Assets ---")
    for rel, size in found_critical:
        print(f"  [✓] {rel} ({size:.2f} MB)")
    for rel in missing_critical:
        print(f"  [❌ MISSING] {rel}")

    print("\n--- Recommended Assets ---")
    for rel, size in found_recommended:
        print(f"  [✓] {rel} ({size:.2f} MB)")
    for rel in missing_recommended:
        print(f"  [⚠️ MISSING] {rel} (Recommended for full campaigns/sounds)")

    # Calculate total size
    total_bytes = sum(f.stat().st_size for f in target_path.rglob('*') if f.is_file())
    total_gb = total_bytes / (1024 * 1024 * 1024)
    print(f"\nTotal game directory size: {total_gb:.2f} GB")

    if missing_critical:
        print("\n[!] VERIFICATION FAILED: The engine will not be able to boot without critical files.")
        return False
    else:
        print("\n[✓] VERIFICATION PASSED: Game files are complete and ready for iOS transfer!")
        return True

def main():
    if len(sys.argv) > 1:
        target = Path(sys.argv[1]).resolve()
    else:
        default_staging = Path(__file__).resolve().parent.parent / "export_for_ios"
        if default_staging.exists():
            target = default_staging
        else:
            print("Usage: python verify_assets.py <path_to_l4d2_folder>")
            sys.exit(1)

    success = verify_directory(target)
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
