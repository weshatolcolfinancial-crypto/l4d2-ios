#!/usr/bin/env python3
"""
Left 4 Dead 2 - iOS IPA Packaging Utility
Packages the compiled .app bundle into an installable .ipa file
ready for TrollStore, AltStore, SideStore, or Sideloadly.
"""

import sys
import shutil
import zipfile
from pathlib import Path

def package_ipa(app_bundle_path: Path, output_ipa_path: Path):
    print("=" * 60)
    print(" Left 4 Dead 2 - iOS IPA Packaging")
    print("=" * 60)

    if not app_bundle_path.exists() or not app_bundle_path.is_dir():
        print(f"[!] Error: App bundle not found at: {app_bundle_path}")
        return False

    temp_dir = app_bundle_path.parent / "ipa_temp"
    payload_dir = temp_dir / "Payload"

    if temp_dir.exists():
        shutil.rmtree(temp_dir)
    payload_dir.mkdir(parents=True, exist_ok=True)

    print(f"[*] Copying {app_bundle_path.name} to Payload/...")
    shutil.copytree(app_bundle_path, payload_dir / app_bundle_path.name, symlinks=True)

    print(f"[*] Compressing into IPA archive: {output_ipa_path.name}...")
    if output_ipa_path.exists():
        output_ipa_path.unlink()

    with zipfile.ZipFile(output_ipa_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for file in temp_dir.rglob('*'):
            rel_path = file.relative_to(temp_dir)
            zipf.write(file, rel_path)

    # Clean up temp
    shutil.rmtree(temp_dir)

    size_mb = output_ipa_path.stat().st_size / (1024 * 1024)
    print(f"[✓] IPA successfully built: {output_ipa_path} ({size_mb:.2f} MB)")
    print("\nSIDELOADING INSTRUCTIONS:")
    print("1. TrollStore (iOS 14 - 17.0): AirDrop or open the .ipa in TrollStore for permanent install.")
    print("2. AltStore / SideStore: Select '+' -> Choose the .ipa to sign and install.")
    print("3. Sideloadly (PC/Mac): Drag and drop the .ipa, enter your Apple ID, and click Start.")
    print("=" * 60)
    return True

def main():
    project_root = Path(__file__).resolve().parent.parent
    build_dir = project_root / "build" / "Release-iphoneos"
    default_app = build_dir / "L4D2IOS.app"
    default_ipa = project_root / "Left4Dead2.ipa"

    if len(sys.argv) > 1:
        app_path = Path(sys.argv[1]).resolve()
    else:
        app_path = default_app

    if len(sys.argv) > 2:
        ipa_path = Path(sys.argv[2]).resolve()
    else:
        ipa_path = default_ipa

    success = package_ipa(app_path, ipa_path)
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
