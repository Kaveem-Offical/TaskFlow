#!/bin/bash
set -e

echo "=== Vercel Flutter Web Build Script ==="

# 1. Install Flutter SDK if not cached
if [ -d "$HOME/flutter" ]; then
  echo "Flutter directory exists at $HOME/flutter"
else
  echo "Cloning stable Flutter SDK..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$HOME/flutter"
fi

# 2. Add Flutter to PATH
export PATH="$PATH:$HOME/flutter/bin"

# 3. Print Flutter version
flutter --version

# 4. Enable Web Support & Get Dependencies
echo "Enabling web support & fetching dependencies..."
flutter config --enable-web
flutter pub get

# 5. Build Flutter Web App for Production
echo "Building Flutter Web release..."
flutter build web --release

echo "=== Build completed successfully! Output in build/web ==="
