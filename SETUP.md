# Quran iOS App Setup Guide

This guide walks you through setting up, building, and deploying the **Kannada Quran** app on Xcode.

---

## Prerequisites

- **macOS** with **Xcode** installed (compatible with Swift 5.10 / Xcode 15+).
- An Apple ID (either a free personal developer account or a paid Apple Developer Program account) for code signing.

---

## 1. Opening the Project

1. Launch Xcode.
2. Select **Open a project or file** and navigate to the repository directory.
3. Open the Xcode Project file:
   `Example/QuranEngineApp.xcodeproj`
   
   *Alternatively, you can open it directly from the terminal:*
   ```bash
   open Example/QuranEngineApp.xcodeproj
   ```

> [!NOTE]
> The project utilizes **Swift Package Manager (SPM)**. Xcode will automatically resolve the local `QuranEngine` package dependency upon opening.

---

## 2. Configuration & Code Signing

Before running on a physical device, you need to configure code signing:

1. In the left navigator, select the top-level project file **QuranEngineApp** (with the blue blueprint icon).
2. Under **Targets**, select **QuranEngineApp**.
3. Go to the **Signing & Capabilities** tab.
4. Ensure **Automatically manage signing** is checked.
5. In the **Team** dropdown, choose your development team:
   * Select your paid Apple Developer Team (if matching `9VM9B8KX27`), or
   * Select your personal Apple ID team (e.g., *Personal Team*).
6. Under **Bundle Identifier**, ensure it is set to `com.quran.kannada`.

---

## 3. Selecting Target and Destination

At the top of the Xcode window, look for the scheme dropdown selectors:

1. **Select Scheme:** Choose **`QuranEngineApp`**.
2. **Select Destination:**
   * **Simulator:** Pick any iOS Simulator (e.g., *iPhone 15*).
   * **Physical Device:** Connect your iPhone via USB/Wi-Fi and select it from the list.

---

## 4. Building and Running

### Running on a Simulator
1. Press **`⌘ + R`** (or click the **Play** button in the top-left corner).
2. Xcode will build and launch the app in the simulator.

### Deploying to a Physical iOS Device
1. **Enable Developer Mode** on your iPhone (required for iOS 16+):
   * Go to **Settings** > **Privacy & Security** > **Developer Mode**.
   * Turn the switch ON and follow the prompts to reboot your device.
2. Connect your iPhone to your Mac via USB.
3. Select your device in the Xcode destination dropdown.
4. Press **`⌘ + R`** to build and install.
5. **Trust the Certificate** (if using a personal certificate):
   * If you receive an *Untrusted Developer* alert on launch, go to **Settings** > **General** > **VPN & Device Management** on your device.
   * Tap your developer profile / Apple ID and choose **Trust**.

---

## Troubleshooting

### Swift Package Resolution Errors
If SPM dependencies fail to resolve or load:
1. Go to **File** > **Packages** > **Reset Package Caches**.
2. Go to **File** > **Packages** > **Resolve Package Versions**.

### Code Signing / Bundle ID Conflict
If you get a signature error using a free Apple ID:
* You may need to change the **Bundle Identifier** under *Signing & Capabilities* to something unique (e.g., `com.yourname.kannadaquran`) since bundle IDs must be globally unique across Apple.
