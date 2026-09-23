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
- **Rename & edit group names** at any time
- Each group card shows today's present / absent / unset count at a glance
- Animated attendance progress bar per group
- Delete groups with confirmation dialog
- **Double-back to exit protection** — prevents accidental app closure on Home
- **In-App Update Alert Banner & Badge** — alerts you immediately when an update is available

### ✅ Attendance Tab
- One-tap **Present ✅ / Absent ❌** toggles per member
- **Quick Phone Dial 📞** — one-tap direct call for absent members with a registered phone number
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

### 📅 Calendar Tab & Member Filtering
- Filter calendar by **All Members** or select an **Individual Member**
- **Weekly, Monthly, and Yearly period metrics** — attendance rate %, present days, absent days, and total sessions
- Detailed period attendance history log per member
- Color-coded calendar day indicators:
  - 🟢 Green — present / full attendance
  - 🟠 Orange — partial attendance
  - 🔴 Red — absent
  - ⚫ Grey — no data
- Tap any date to see the complete attendance snapshot for that day
- Direct Quick Dial button for absent members on selected dates

### ⚙️ Settings, Data & Backup
- **Theme switcher** with color swatch previews
- **Sound & Haptics** — toggle UI click sounds and subtle tactile vibration feedback
- **Local Storage Warning** — clear warning advising that clearing app data deletes attendance data permanently
- **Full JSON Backup Export** — one-tap export of all groups, members, and complete historical attendance records
- **Dataset Import** — restore or merge backup datasets directly from `.json` files or clipboard text with Merge / Replace options
- **CSV export per group** — share attendance spreadsheets via any Android app
- **GitHub Repository** — instant link to source repository in browser
- **Auto-update with Streamed Download & Install** — download progress bar and direct package installer launch
- **App version and about info**

### 🔔 Auto-Update & Notification System
- **Background Check on Launch**: Automatically queries GitHub Releases without interrupting your workflow
- **Android System Notification**: Pops in the Android notification tray (`simple_attende_updates` high-priority channel)
- **In-App Notification Banner**: Dismissible floating banner on the dashboard with direct "Update" action
- **Changelog Dialog**: Displays latest release notes and highlights
- **Real-Time Streamed APK Download**: Progress bar with percentage and downloaded MB / total MB metrics
- **Native Package Installer**: Automatically launches Android's package installer when the APK download finishes

### 🔊 Sound Effects & Haptics
- **Polyphonic low-latency audio pool**: Rapid consecutive button clicks play simultaneously without truncating preceding audio
- **HD uncompressed audio playback**: Packed with Android AAPT `noCompress` rules
- **Subtle haptic feedback**: Instant tactile response on taps and saves

---

## 🎬 Intro Animation & Adaptive Icon

- On every app launch, the **Simple Attende logo slides in from the left** with a smooth spring animation, a dynamic glow effect, and the intro sound plays simultaneously. The screen then fades out to the home page. The splash background color matches your selected theme. Tap anywhere to skip.
- **Optimized Android Adaptive Icon**: Engineered with calibrated safe-zone inner padding so circular and squircle launcher masks display the full emblem cleanly with zero magnification or edge clipping.

---

## 🗂️ Data & Privacy

- **100% local** — all data stays on your device in Android SharedPreferences
- **No cloud dependency** — no accounts, no sign-in, no tracking
- **Backup & Restore** — export and import full JSON backup datasets at any time (supporting both merge and replace)
- **Warning**: Because all data is strictly stored locally, clearing app data or uninstalling will permanently remove all records. Always keep exported backups safe!

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
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
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
│   │   └── local_storage.dart       # SharedPreferences wrapper + Backup JSON export & parser
│   └── models/
│       ├── group_model.dart         # Group + Member models with JSON serialization
│       └── attendance_model.dart    # AttendanceRecord, AttendanceStatus, AttendanceData + merge()
│
├── providers/
│   ├── settings_provider.dart       # Theme + sound/haptic state management
│   ├── groups_provider.dart         # Group/member CRUD + importGroups()
│   ├── attendance_provider.dart     # Attendance state, midnight reset, CSV export + importAttendance()
│   └── update_provider.dart         # Auto-check, streamed download, native installer, notifications
│
├── screens/
│   ├── intro/
│   │   └── intro_screen.dart        # Slide-in logo animation + sound
│   ├── home/
│   │   └── home_screen.dart         # Groups dashboard + in-app update banner & popup
│   ├── group/
│   │   ├── group_screen.dart        # Tab container + group header
│   │   └── tabs/
│   │       ├── attendance_tab.dart  # Daily attendance with toggles + Quick Dial
│   │       ├── members_tab.dart     # Member CRUD + category manager
│   │       └── calendar_tab.dart    # Calendar + per-member filter & period stats
│   └── settings/
│       └── settings_screen.dart     # Theme, sound/haptic, warning card, JSON export/import, update progress
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
| `path_provider` | ^2.1.3 | File paths for CSV, JSON & APK downloads |
| `share_plus` | ^10.0.0 | Share CSV & JSON backups via Android apps |
| `file_picker` | ^8.1.7 | File picker for backup dataset restore |
| `http` | ^1.2.0 | GitHub update check & streamed APK download |
| `flutter_animate` | ^4.5.0 | UI animations |

---

## 🔄 Auto-Update & Notifications

Simple Attende automatically checks [GitHub Releases](https://github.com/KHILVANSH6789/Simple-Attende/releases) for new versions on launch:
- **System Notification**: Alerts your Android notification tray when an update is released.
- **In-App Notification & Popup**: Shows an animated update banner on the Home dashboard and a changelog popup dialog.
- **One-Tap Auto-Download & Install**: Streamed APK download with real-time percentage and MB progress that launches Android's package installer seamlessly.
- **Manual Check**: Go to **Settings → Updates → Check** at any time.

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
