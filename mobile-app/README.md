# SmartCalm — Mobile App

![Flutter](https://img.shields.io/badge/Flutter-Dart-02569B) ![Android](https://img.shields.io/badge/Platform-Android-3DDC84) ![Supabase](https://img.shields.io/badge/Supabase-Auth_%26_Storage-3ECF8E)

The SmartCalm companion app — a Flutter application that connects to the SmartCalm backend to display real-time stress readings, historical trends, calming activities, and a personal journal, giving users an interface into the data their wristband collects.

## Features

- Real-time stress level display (Calm / Mild / High), synced from the backend
- Historical trends and weekly stress reports
- Guided calming activities (breathing exercises, sound-based relaxation) with session tracking
- Personal journal tied to stress readings
- User preferences (alerts, wearable feedback, preferred calm activities)
- Full auth flow: sign up, log in, password recovery, and a guest mode for trying the app without an account
- Supabase-backed authentication and data storage

## Repository Structure

```
mobile-app/
├─ README.md
├─ pubspec.yaml
├─ pubspec.lock
├─ analysis_options.yaml
├─ .gitignore
├─ lib/
│  ├─ main.dart
│  ├─ core/theme/       — shared app theming
│  ├─ screens/          — one file per app screen
│  └─ widgets/          — reusable UI components
├─ assets/
│  ├─ images/
│  └─ sounds/
├─ android/              — Android build configuration
└─ ios/                  — iOS project scaffold (see note below)
```

## Platform Support

This app is built and tested for **Android**. The `ios/` folder contains Flutter's generated iOS project scaffold, but it has not been built or run — iOS development requires Xcode, which requires macOS, and this project was developed on Windows. Anyone wanting to build for iOS will need to open the project on macOS, generate a `Podfile` via `pod install`, and resolve any platform-specific issues from there.

## Requirements

- Flutter SDK (stable channel)
- Android Studio or VS Code with the Flutter/Dart extensions
- An Android device or emulator

## How to Run

1. Clone the repository and navigate to this folder:
   ```bash
   git clone https://github.com/JanaM-10/SmartCalm.git
   cd SmartCalm/mobile-app
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Configure your backend/Supabase connection details (see Configuration below).
4. Run on a connected device or emulator:
   ```bash
   flutter run
   ```

## Configuration

The Supabase project URL and **anon (publishable) key** are set directly in `lib/main.dart`. This is safe by design — the anon key is meant to be shipped in client apps, and actual data access is restricted by Row Level Security policies defined in the backend's `supabase_schema.sql` (users can only read/write their own data). No secret credentials are exposed here.

For flexibility (e.g., switching between a dev and production Supabase project without editing source code), this could later be moved to Flutter's `--dart-define` build-time variables — but this is a convenience improvement, not a security fix.

## Future Improvements

- Add automated widget/integration tests
- Complete and test iOS build support
- Add app screenshots to `../media/` for the root README
