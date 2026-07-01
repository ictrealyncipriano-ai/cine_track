# Build Commands

## Prerequisites
Set `JAVA_HOME` to JDK 21 before any build:
```powershell
$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-21.0.9.10-hotspot"
```

## Android Emulator
```powershell
$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-21.0.9.10-hotspot"
flutter build apk --dart-define=ANDROID_EMULATOR=true --no-tree-shake-icons
```
Sets `API_BASE_URL` to `http://10.0.2.2/cine_track/api` (reaches host machine from emulator).

## Physical Device / Production
```powershell
$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-21.0.9.10-hotspot"
flutter build apk --release --dart-define=API_BASE_URL=https://your-domain.com/api --no-tree-shake-icons
```

## Custom Port (e.g. XAMPP on port 8080)
```powershell
$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-21.0.9.10-hotspot"
flutter build apk --dart-define=API_BASE_URL=http://10.0.2.2:8080/cine_track/api --dart-define=ANDROID_EMULATOR=true --no-tree-shake-icons
```

## Notes
- CMake 3.31.6 installed at `C:\Android\cmake\3.31.6` (set via `android.cmakeVersion=3.31.6` in `gradle.properties`)
- `--no-tree-shake-icons` required for release builds (font-subset.exe crash on this Flutter version)
