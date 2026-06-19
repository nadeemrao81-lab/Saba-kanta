# SABA KANTA - Weighbridge Management App
## Complete Build & Setup Guide

---

## App Overview
**SABA ISLAMI COMPUTERIZED KANTA** - A full-featured offline weighbridge management app for grain markets.

- **Platform:** Android (Flutter)
- **Language:** English
- **Storage:** SQLite (100% Offline)
- **Print Size:** A5 Portrait

---

## Project Structure

```
saba_kanta/
├── lib/
│   ├── main.dart                    ← App entry, splash screen
│   ├── models/
│   │   └── weigh_record.dart        ← Data model
│   ├── database/
│   │   └── database_helper.dart     ← SQLite CRUD operations
│   ├── screens/
│   │   ├── entry_form_screen.dart   ← Main entry form (home screen)
│   │   └── records_list_screen.dart ← Search, view, edit, delete
│   └── printing/
│       ├── receipt_generator.dart   ← A5 PDF receipt (matches sample)
│       └── print_service.dart       ← System/BT/USB print, preview, export
├── android/
│   └── app/src/main/
│       └── AndroidManifest.xml      ← All permissions declared
└── pubspec.yaml                     ← All dependencies
```

---

## Prerequisites

### 1. Install Flutter SDK
```bash
# Download from: https://flutter.dev/docs/get-started/install
# Recommended: Flutter 3.19+ (Dart 3.0+)

# Verify installation
flutter doctor
```

### 2. Install Android Studio
- Download: https://developer.android.com/studio
- Install Android SDK (API 21+)
- Set up an Android Virtual Device (AVD) OR use a real device

### 3. Install Java JDK 17
```bash
# Ubuntu/Debian
sudo apt install openjdk-17-jdk

# macOS (Homebrew)
brew install openjdk@17

# Windows: Download from https://adoptium.net/
```

---

## Build Instructions

### Step 1: Clone/Copy the Project
```bash
cd ~
# Copy the saba_kanta folder to your workspace
cp -r /path/to/saba_kanta ~/workspace/saba_kanta
cd ~/workspace/saba_kanta
```

### Step 2: Get Dependencies
```bash
flutter pub get
```

### Step 3: Fix Gradle (if needed)
Edit `android/app/build.gradle`:
```gradle
android {
    compileSdkVersion 34
    defaultConfig {
        applicationId "com.sabakanta.app"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }
}
```

Edit `android/build.gradle`:
```gradle
buildscript {
    ext.kotlin_version = '1.9.0'
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:8.1.0'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    }
}
```

### Step 4: Build Debug APK (for testing)
```bash
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

### Step 5: Build Release APK
```bash
# Generate keystore (first time only)
keytool -genkey -v -keystore ~/saba_kanta.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias sabakanta

# Create key.properties in android/ folder:
cat > android/key.properties << 'EOF'
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=sabakanta
storeFile=/home/YOUR_USER/saba_kanta.jks
EOF

# Build release APK
flutter build apk --release --split-per-abi

# Output APKs (install the matching one for your device):
# build/app/outputs/flutter-apk/app-arm64-v8a-release.apk  ← Most modern phones
# build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk ← Older phones
# build/app/outputs/flutter-apk/app-x86_64-release.apk     ← Emulators
```

### Step 6: Install on Device
```bash
# Enable USB Debugging on Android phone:
# Settings → About Phone → Tap Build Number 7 times → Developer Options → USB Debugging ON

# Install via ADB
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

# OR transfer APK file to phone and install directly
```

---

## Printer Setup

### HP LaserJet 1320 (via USB / WiFi)
1. Connect printer to Android phone via USB OTG adapter
2. In app → Print button → Select "Print"
3. Android Print dialog opens → Select HP LaserJet 1320
4. Set paper size to A5 → Print

### Canon LBP3050 (via Android Print Service)
1. Install **Canon PRINT Service** from Google Play Store
2. Connect printer to same WiFi as phone
3. In app → Print → Select Canon LBP3050 from dialog
4. Paper: A5 Portrait → Print

### Bluetooth Thermal Printer
1. Pair your Bluetooth printer in Android Settings → Bluetooth
2. In app → "BT Print" button
3. Tap "Scan" → Select your printer → Print

---

## App Features

### Entry Form Screen (Home)
| Feature | Description |
|---------|-------------|
| Auto Serial No | Increments automatically from database |
| Party Name | UPPERCASE auto-format |
| Commodity | UPPERCASE auto-format |
| Driver Name | Optional |
| Vehicle No | Optional |
| 1st Weight | In Maunds, large display |
| 2nd Weight | In Maunds, large display |
| Net Weight | Auto = 1st - 2nd (green display) |
| Rate/Maund | In Rs. |
| Total Amount | Auto = Net × Rate (blue display) |
| Date/Time | Auto-filled on save |

### Action Buttons
| Button | Action |
|--------|--------|
| Save & Print | Saves to SQLite + opens print preview |
| New | Clears form for new entry |
| Preview | PDF preview in A5 |
| Print | Opens Android print dialog |
| Export PDF | Share/save PDF file |
| BT Print | Bluetooth printer selection |

### Records List Screen
| Feature | Description |
|---------|-------------|
| Search by Party | Real-time search |
| Search by Vehicle | Real-time search |
| Edit | Opens pre-filled form |
| Delete | Confirmation dialog |
| Reprint | Print any old receipt |
| Total Summary | Shows sum of all filtered records |

---

## Receipt Layout (A5 Portrait)

```
┌────────────────────────────────────┐
│  SABA ISLAMI COMPUTERIZED KANTA    │
│  Kabirwala Khanewal . Ph: 0300...  │
├────────────────────────────────────┤
│ S.No        00000332               │
│ Party Name  MIAN ALI RUMAIS...     │
│ Commodity   MANGO                  │
│ Driver                             │
│ Vehicle No  RAKSHA                 │
│                       Date   Time  │
│                    17-Jun-26 11:48 │
│                                    │
│ 1st Weight                         │
│    420 M                           │
│                                    │
│ 2nd Weight                         │
│      0                             │
│                                    │
│ Net Weight                         │
│    420 M                           │
│                                    │
├────────────────────────────────────┤
│ Price Rs. 80   Mnds 40 Kg.    Kgs  │
│ Total Amount Rs. 33,600.00         │
└────────────────────────────────────┘
```

---

## Database Schema

```sql
CREATE TABLE weigh_records (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    serialNo    INTEGER NOT NULL,
    partyName   TEXT NOT NULL,
    commodity   TEXT NOT NULL,
    driverName  TEXT,
    vehicleNo   TEXT,
    firstWeight REAL NOT NULL,    -- in Maunds
    secondWeight REAL NOT NULL,   -- in Maunds
    netWeight   REAL NOT NULL,    -- Auto: first - second
    ratePerMaund REAL NOT NULL,   -- Rs. per Maund
    totalAmount REAL NOT NULL,    -- Auto: net * rate
    date        TEXT NOT NULL,    -- DD-Mon-YY
    time        TEXT NOT NULL     -- HH:MM AM/PM
);
```

---

## Troubleshooting

### Build fails: SDK not found
```bash
flutter doctor --android-licenses
```

### Bluetooth not working
- Check: Android 12+ requires BLUETOOTH_SCAN + BLUETOOTH_CONNECT permissions
- Must be granted at runtime (permission_handler handles this)

### PDF not generating
```bash
flutter pub upgrade printing pdf
```

### SQLite errors
```bash
flutter pub upgrade sqflite
```

---

## Version History
- v1.0.0 - Initial release
  - Full entry form with auto-calculations
  - SQLite offline storage
  - A5 PDF receipt matching SABA ISLAMI sample
  - Bluetooth + USB OTG + System print support
  - Search, Edit, Delete, Reprint features
