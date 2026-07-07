#!/bin/bash
set -e
curl -sSL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.44.4-stable.tar.xz | tar xJ -C /tmp
git config --global --add safe.directory /tmp/flutter
export PATH="/tmp/flutter/bin:$PATH"
flutter config --no-analytics
flutter pub get
flutter build web --release --no-tree-shake-icons
