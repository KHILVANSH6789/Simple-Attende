# Simple Attende — Flutter Attendance App

A beautiful, local-first attendance tracking Android application built with Flutter.

## Features

- 🗂 **Multiple Groups** — Create attendance groups for clinics, classes, teams, or any setting
- ✅ **Smart Attendance** — Mark present/absent with timestamps; auto-resets at midnight
- 👥 **Custom Member Profiles** — Define your own data categories (Name, Age, Phone, etc.)
- 📅 **Calendar View** — Browse attendance history with color-coded day indicators
- 🎨 **3 Beautiful Themes** — Mystic Night, Cotton Candy Pink, Sky Blue
- 🔊 **Sound Effects** — Satisfying audio feedback for every interaction
- 📤 **CSV Export** — Share attendance data via any Android app
- 🔄 **Auto-Update Checker** — Fetches latest release from GitHub

## Getting Started

### Prerequisites
- Flutter SDK ≥ 3.0
- Android Studio / VS Code
- Android device or emulator

### Run the app
```bash
flutter pub get
flutter run
```

### Build APK
```bash
flutter build apk --release
```

## Project Structure
```
lib/
├── main.dart               # Entry point
├── app.dart                # Root widget + routing
├── core/
│   ├── theme/              # 3 themes + color tokens
│   ├── storage/            # SharedPreferences wrapper
│   └── models/             # Group, Member, Attendance models
├── providers/              # State management (Provider)
├── screens/
│   ├── intro/              # Animated splash screen
│   ├── home/               # Groups dashboard
│   ├── group/              # Group detail + 3 tabs
│   └── settings/           # Theme, sound, export, updates
└── widgets/                # Reusable components
```

## Assets
- `assets/images/SimpleAttende_AppIcon.png` — App icon used in splash
- `assets/audio/Intro_Sound.mp3` — Plays during splash animation
- `assets/audio/Button_Click.mp3` — UI interaction sound
- `assets/audio/Save_Button.mp3` — Save confirmation sound

## License
MIT
