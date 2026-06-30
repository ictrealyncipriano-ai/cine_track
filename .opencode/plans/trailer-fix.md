# Fix: YouTube Error 153 in Teaser Player

## Problem
YouTube's embed URL (`/embed/KEY`) is blocked in InAppWebView due to missing origin/referrer validation, causing Error 153 ("Video player configuration error").

## Fix: Option A — Use YouTube watch page URL instead of embed

### Single file change

**File:** `lib/models/trailer_video.dart`

**Change:**
```dart
// Before (embed - broken in WebView):
String get youtubeUrl =>
    'https://www.youtube.com/embed/${key}?autoplay=1&rel=0&modestbranding=1';

// After (watch page - works reliably in WebView):
String get youtubeUrl =>
    'https://www.youtube.com/watch?v=$key';
```

### How it works
- YouTube's main `/watch?v=KEY` page auto-detects mobile WebView and serves the native mobile player
- Handles ads, age restrictions, and regional blocks that the embed ignores
- No `autoplay=1` needed — user taps the play button on the page

### Build
- Update the APK after the change: `flutter build apk --release --dart-define=API_BASE_URL=https://cine-track-delta.vercel.app/api`
- No server-side changes needed (no PHP changes, no DB migration)

### Total effort: ~2 minutes + build time
