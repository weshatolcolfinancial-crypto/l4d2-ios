# Left 4 Dead 2 - Native iOS Port

A native iOS runtime and wrapper for Left 4 Dead 2 PC (Steam content), featuring **120Hz ProMotion** support, **dynamic floating touch controls**, dedicated **L4D2 gameplay & melee buttons**, an automated **SteamCMD PC asset downloader**, and an integrated **real-time diagnostic logging system**.

---

## Key Features

- **Native ARM64 iOS Runtime**: Runs compiled C++ and Metal rendering on Apple Silicon (A-series and M-series chips).
- **ProMotion 120Hz High-Refresh Support**: Configured with `CADisplayLink.preferredFrameRateRange = (60, 120, 120)` and `CADisableMinimumFrameDurationOnPhone` in `Info.plist` for ultra-smooth 120 FPS gameplay.
- **Dynamic Floating Joystick**:
  - Touch anywhere on the left screen quadrant to center the joystick directly under your thumb.
  - Configurable deadzone and normalized vector dispatch to Source engine movement (`+forward`, `+back`, `+moveleft`, `+moveright`).
- **L4D2 Combat & Interaction Buttons**:
  - **FIRE** (`+attack`): Primary weapon fire.
  - **SHOVE / MELEE** (`+attack2`): Quick horde shove / melee swing (vital for repelling Boomers, Hunters, and common infected swarms).
  - **JUMP** (`+jump`): Jump and bunnyhop.
  - **CROUCH** (`+duck`): Toggleable crouch.
  - **USE** (`+use`): Revive teammates, open doors, pour gas cans, deploy ammo.
  - **RELOAD** (`+reload`): Tactical weapon reload.
  - **LIGHT** (`impulse 100`): Flashlight toggle.
- **5-Slot L4D2 Inventory Switcher**:
  - **Slot 1**: Primary Weapon (Rifles, Shotguns, SMGs, Snipers)
  - **Slot 2**: Secondary (Pistols, Magnum, Melee: Fireaxe, Katana, Baseball Bat, etc.)
  - **Slot 3**: Throwables (Pipe Bomb, Molotov, Bile Jar)
  - **Slot 4**: First Aid Kit / Defibrillator / Upgrade Ammo
  - **Slot 5**: Pain Pills / Adrenaline Shot
- **Asset Ingestion Pipeline**:
  - Download official Steam PC files via command-line using `steamcmd`.
  - Expose app directory directly in the native **iOS "Files" app** (`On My iPhone -> L4D2 iOS`) and **iTunes / Finder File Sharing** (`UIFileSharingEnabled = true`).
- **Comprehensive Troubleshooting & Logging**:
  - All engine messages (`DevMsg`, `Warning`, `Error`, SpewOutputFunc) are mirrored to `Documents/debug.log`.
  - On-screen debug console view toggled with a quick tap of the **LOGS** button.
  - Real-time telemetry: FPS, frame time (ms), RAM usage (MB) against iOS Jetsam thresholds.
  - Asset integrity validator: If game files are missing, the app displays a clear setup card instead of an unexplained crash.

---

## Directory Structure

```
L4D2 IOS/
├── CMakeLists.txt              # CMake configuration for iOS ARM64 bundle
├── README.md                   # Complete documentation
├── cmake/
│   └── ios.toolchain.cmake     # iOS cross-compilation toolchain
├── ios/
│   ├── Info.plist              # Configured for File Sharing, 120Hz, and Landscape
│   └── src/
│       ├── main.mm             # iOS application entry point
│       ├── AppDelegate.h / .mm # App lifecycle, audio session, idle timer
│       ├── GameViewController.h / .mm # Root controller, views, asset setup prompt
│       └── MetalView.h / .mm   # CAMetalLayer backing view
├── src/
│   ├── core/
│   │   ├── types.h             # Input commands bitmask and structs
│   │   ├── engine_bridge.h / .cpp # Bridge connecting iOS layer to Source engine
│   │   └── promotion_manager.h / .mm # 120Hz ProMotion CADisplayLink manager
│   ├── touch/
│   │   ├── dynamic_joystick.h / .mm  # Dynamic floating left thumbstick
│   │   ├── touch_buttons.h / .mm     # Combat buttons (Fire, Shove, Use, etc.)
│   │   ├── weapon_switcher.h / .mm   # 5-slot L4D2 inventory bar
│   │   └── touch_controller.h / .mm  # Multi-touch dispatcher and overlay UI
│   └── logging/
│       ├── logger.h / .cpp           # Persistent file logger & ring buffer
│       ├── asset_validator.h / .cpp  # Asset integrity verification
│       └── debug_overlay.h / .mm     # Live on-screen console overlay
└── tools/
    ├── download_steam_assets.py      # Automated steamcmd asset downloader
    ├── download_steam_assets.bat     # Windows 1-click download launcher
    ├── verify_assets.py              # Cross-platform asset checker
    └── package_ipa.py                # Xcode app to .ipa packager
```

---

## Step 1: Downloading Game Content via CMD

You do not need to install the heavy Steam client or copy unnecessary Windows `.exe`/DirectX files. Use the provided automated downloader:

### On Windows:
Double-click `tools\download_steam_assets.bat` or run:
```cmd
python tools\download_steam_assets.py
```

### How it works:
1. Automatically verifies or downloads portable `steamcmd`.
2. Downloads clean Left 4 Dead 2 PC content (Steam App ID **550**).
3. Strips unneeded `.exe` and `.dll` binaries, staging only the required game folders into `export_for_ios/`:
   - `left4dead2/` (containing `*_dir.vpk`, maps, sound caches)
   - `hl2/` (base engine shared content)

You can verify the staged content anytime:
```cmd
python tools\verify_assets.py export_for_ios
```

---

## Step 2: Transferring Content to iPhone / iPad

Because `UIFileSharingEnabled` and `LSSupportsOpeningDocumentsInPlace` are enabled in `Info.plist`, you have two easy transfer methods:

### Option A: Via Native iOS "Files" App
1. Open the **Files** app on your iPhone or iPad.
2. Tap **Browse** -> **On My iPhone** (or **On My iPad**).
3. Open the **L4D2 iOS** folder.
4. Copy the `left4dead2` and `hl2` folders directly inside (via AirDrop, network share, or USB-C drive).

### Option B: Via PC / Mac USB (iTunes / Finder)
1. Plug your device into your PC/Mac via USB.
2. Open **iTunes**, **Apple Devices app**, or macOS **Finder**.
3. Select your device -> Click **File Sharing** -> Select **L4D2 iOS**.
4. Drag and drop the `left4dead2` and `hl2` folders directly into the file list.

---

## Step 3: Building the IPA

### Build using CMake & Xcode:
```bash
# 1. Create build directory
mkdir build && cd build

# 2. Configure with iOS toolchain
cmake .. -G Xcode -DCMAKE_TOOLCHAIN_FILE=../cmake/ios.toolchain.cmake -DPLATFORM=OS64

# 3. Build Release binary
cmake --build . --config Release
```

### Packaging into `.ipa`:
```bash
python tools/package_ipa.py build/Release-iphoneos/L4D2IOS.app Left4Dead2.ipa
```

---

## Step 4: Sideloading onto iOS Device

Choose your preferred sideloading utility:

| Method | Compatibility | JIT / Revoke Notes |
| :--- | :--- | :--- |
| **TrollStore** | iOS 14.0 - 17.0 | Permanent install, 0 revokes, full root permissions. (Recommended) |
| **AltStore / SideStore** | iOS 14.0 - Current | Re-signs weekly using your personal Apple ID. |
| **Sideloadly** | PC / Mac | Direct drag-and-drop IPA installation over USB/Wi-Fi. |
| **Apple Developer** | All versions | 1-year signing certificate with native Xcode debugging. |

---

## Troubleshooting & Diagnostics

### Missing Assets Screen at Launch:
If you launch the app before copying your game files, the app does not crash. Instead, it displays the **Content Required** guidance card with the exact missing files and paths. Tap **RECHECK FILES** once you finish copying.

### Checking `debug.log`:
- The app automatically logs all startup steps, asset paths, shader compilations, and engine events to `Documents/debug.log`.
- You can read `debug.log` anytime directly on your iPhone using the iOS **Files** app, or tap the on-screen **LOGS** button to toggle the live in-engine debug console.
- In the live console, tap **EXPORT** to instantly share the log file via AirDrop, Mail, or Notes.
