# Build Commands

## Prerequisites
Set `JAVA_HOME` to JDK 21 before any build:
```powershell
$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-21.0.9.10-hotspot"
```

## All Builds (Emulator, Physical Device, Production)
```powershell
$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-21.0.9.10-hotspot"
flutter build apk --release --no-tree-shake-icons --android-skip-build-dependency-validation
```

The `--android-skip-build-dependency-validation` flag is required because:
- `objective_c` (transitive via `google_fonts` → `path_provider` → `path_provider_foundation`) has a native asset hook that crashes the Dart kernel compiler on Windows (STATUS_ACCESS_VIOLATION). This hook is only needed for iOS/macOS but Flutter's build system attempts to compile it for all platforms.
- The `jni` plugin (transitive via `google_fonts` → `path_provider` → `path_provider_android`) requests NDK 28.x, while the project pins NDK 27.x. The flag bypasses this version check.

The API URL is now determined **automatically at runtime**:
- **Android Emulator** → auto-detected, uses `http://10.0.2.2/cine_track/api`
- **Physical Device** → uses `https://cine-track-delta.vercel.app/api` (production)

The **current API URL** is displayed in small text below the title on the login screen.

To override the API URL at runtime, **long-press the "Welcome Back" title** (or the URL text itself) on the login screen and enter a custom URL (persisted across app restarts).

To debug, run `flutter logs` while the app is starting — look for `AppConfig:` in the log output.

## Web Build & Deploy
```powershell
$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-21.0.9.10-hotspot"
flutter build web --release --no-tree-shake-icons
```

The web app is deployed to the same Vercel project as the PHP API (`cine-track-delta.vercel.app`).
It auto-detects the web platform and uses the production API URL.
Deploy via `vercel --prod --confirm` from the project root.

## Notes
- CMake 3.31.6 installed at `C:\Android\cmake\3.31.6` (set via `android.cmakeVersion=3.31.6` in `gradle.properties`)
- `--no-tree-shake-icons` required for release builds (font-subset.exe crash on this Flutter version)
- `dependency_overrides: path_provider_android: 2.2.23` in `pubspec.yaml` — avoids the `jni-1.0.0` transitive dependency (which has a native CMake build that crashes on Windows: `ninja: CreateProcess: Access is denied` when running NDK `clang.exe`).
- The `objective_c-9.4.1` package's `hook/` directory is renamed to `hook.bak` in the pub cache to skip its native asset hook (crashes the Dart AOT snapshotter on Windows with `STATUS_ACCESS_VIOLATION` on Android builds). The hook is only needed for iOS/macOS.
