# Build Commands

## Android Emulator
```bash
flutter build apk --dart-define=ANDROID_EMULATOR=true
```
Sets `API_BASE_URL` to `http://10.0.2.2/cine_track/api` (reaches host machine from emulator).

## Physical Device / Production
```bash
flutter build apk --dart-define=API_BASE_URL=https://your-domain.com/api
```

## Custom Port (e.g. XAMPP on port 8080)
```bash
flutter build apk --dart-define=API_BASE_URL=http://10.0.2.2:8080/cine_track/api --dart-define=ANDROID_EMULATOR=true
```
