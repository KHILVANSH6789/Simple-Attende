<div align="center">

<img src="assets/images/SimpleAttende_AppIcon.png" width="120" alt="Simple Attende Logo" />

# Simple Attende

**Attendance tracking, beautifully simplified.**

[![Flutter](https://img.shields.io/badge/Flutter-3.47.5-02569B?style=flat-square&logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=flat-square&logo=dart)](https://dart.dev)
[![Android](https://img.shields.io/badge/Android-5.0+-3DDC84?style=flat-square&logo=android)](https://android.com)
[![License](https://img.shields.io/badge/License-MIT-purple?style=flat-square)](LICENSE)
[![Release](https://img.shields.io/github/v/release/KHILVANSH6789/Simple-Attende?style=flat-square&color=blueviolet)](https://github.com/KHILVANSH6789/Simple-Attende/releases)

</div>

---

## 📱 Overview

**Simple Attende** is a local-first Android attendance tracking app built with Flutter. Designed for clinics, classrooms, gyms, or any setting where you need to track people — it stores all data on your device with no account required, no cloud, no subscriptions.

---

## ✨ Features

### 🎨 Three Premium Themes
| Mystic Night | Cotton Candy | Sky Blue |
|:---:|:---:|:---:|
| Dark violet & purple | Soft pink & rose | Clear blue & sky |
| Default theme | Warm & playful | Clean & calm |

### 🏠 Groups Dashboard
- Create unlimited attendance groups (clinic, class, team, gym — anything)
- Each group card shows today's present / absent / unset count at a glance
- Animated attendance progress bar per group
- Delete groups with confirmation

### ✅ Attendance Tab
- One-tap **Present ✅ / Absent ❌** toggles per member
- Timestamps recorded when attendance is marked
- **Mark All Present / Mark All Absent** quick actions
- Live search to filter members instantly
- Daily summary badges (Present · Absent · Not Set)
- **Auto-resets at midnight** — every day starts fresh, history is preserved

### 👥 Members Tab
- Add members with any data fields you define
- **Custom categories** — Name, Age, Phone, Address, or create your own (Room No., Email, etc.)
- Edit or delete members at any time
- Searchable member list
- Category manager to add/remove fields without losing data

### 📅 Calendar Tab
- Full monthly calendar with **color-coded day indicators**:
  - 🟢 Green — full attendance
  - 🟠 Orange — partial attendance
  - 🔴 Red — all absent
  - ⚫ Grey — no data
- Tap any date to see the complete attendance snapshot for that day
- Per-member status with timestamps for historical dates

### ⚙️ Settings
- **Theme switcher** with color swatch previews
- **Sound effects toggle** — enable/disable UI sounds
- **CSV export** — share attendance data for any group via any Android app
- **Auto-update checker** — checks GitHub for newer releases
- App version and about info

### 🔊 Sound Effects
| Sound | Trigger |
|-------|---------|
| `Intro_Sound.mp3` | Splash screen animation |
| `Button_Click.mp3` | Navigation and UI interactions |
| `Save_Button.mp3` | Saving members and groups |

---

## 🎬 Intro Animation

On every app launch, the **Simple Attende logo slides in from the left** with a smooth spring animation, a dynamic glow effect, and the intro sound plays simultaneously. The screen then fades out to the home page. The splash background color matches your selected theme. Tap anywhere to skip.

---

## 🗂️ Data & Privacy

- **100% local** — all data stays on your device in Android SharedPreferences
- No internet connection required (except for the optional update check)
- No accounts, no sign-in, no cloud sync
- Export your data at any time as a CSV file

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) ≥ 3.0.0
- Android Studio or VS Code with Flutter extension
- Android device or emulator (Android 5.0+)

### Run from source
```bash
git clone https://github.com/KHILVANSH6789/Simple-Attende.git
cd Simple-Attende
flutter pub get
flutter run
```

### Install the APK directly
Download the latest release APK from the [Releases page](https://github.com/KHILVANSH6789/Simple-Attende/releases) and install it on your Android device.

> **Note:** You may need to enable *Install from unknown sources* in your Android settings.

---

## 🔨 Build

### Debug APK
```bash
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

### Release APK
```bash
flutter build apk --release --shrink
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Split APKs by ABI (smaller file per device)
```bash
flutter build apk --split-per-abi --release
```

---

## 🗃️ Project Structure

```
lib/
├── main.dart                        # Entry point, portrait lock, storage init
├── app.dart                         # Root widget, providers, routing
│
├── core/
│   ├── theme/
│   │   └── app_theme.dart           # 3 themes with full color tokens + Material ThemeData
│   ├── storage/
│   │   └── local_storage.dart       # SharedPreferences wrapper
│   └── models/
│       ├── group_model.dart         # Group + Member models with JSON serialization
│       └── attendance_model.dart    # AttendanceRecord, AttendanceStatus, AttendanceData
│
├── providers/
│   ├── settings_provider.dart       # Theme + sound state management
│   ├── groups_provider.dart         # Group/member CRUD
│   └── attendance_provider.dart     # Attendance state, midnight reset, CSV export
│
├── screens/
│   ├── intro/
│   │   └── intro_screen.dart        # Slide-in logo animation + sound
│   ├── home/
│   │   └── home_screen.dart         # Groups dashboard + create group dialog
│   ├── group/
│   │   ├── group_screen.dart        # Tab container + group header
│   │   └── tabs/
│   │       ├── attendance_tab.dart  # Daily attendance with toggles
│   │       ├── members_tab.dart     # Member CRUD + category manager
│   │       └── calendar_tab.dart    # Monthly calendar + historical view
│   └── settings/
│       └── settings_screen.dart     # Theme, sound, export, update checker
│
└── widgets/
    └── group_card.dart              # Animated group card with stats
```

---

## 📦 Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `provider` | ^6.1.2 | State management |
| `shared_preferences` | ^2.3.0 | Local data persistence |
| `audioplayers` | ^6.1.0 | Sound effects |
| `table_calendar` | ^3.1.2 | Calendar widget |
| `google_fonts` | ^6.2.1 | Space Grotesk + Nunito fonts |
| `intl` | ^0.19.0 | Date formatting |
| `uuid` | ^4.4.0 | Unique IDs for groups/members |
| `path_provider` | ^2.1.3 | File paths for CSV export |
| `share_plus` | ^10.0.0 | Share CSV via Android apps |
| `http` | ^1.2.0 | GitHub update check |
| `flutter_animate` | ^4.5.0 | UI animations |

---

## 🔄 Auto-Update

Simple Attende checks [GitHub Releases](https://github.com/KHILVANSH6789/Simple-Attende/releases) for newer versions. Go to **Settings → Updates → Check** to compare your current version with the latest release tag. If a new version is available, a banner will appear prompting you to download it.

---

## 🤝 Contributing

Pull requests are welcome! For major changes, please open an issue first.

1. Fork the repository
2. Create your feature branch: `git checkout -b feat/your-feature`
3. Commit your changes: `git commit -m 'feat: add your feature'`
4. Push to the branch: `git push origin feat/your-feature`
5. Open a Pull Request

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

<div align="center">

Made with ❤️ and Flutter

</div>
