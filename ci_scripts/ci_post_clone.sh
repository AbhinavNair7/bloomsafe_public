#!/bin/sh

# Simple CI post-clone script for Xcode Cloud
set -e

echo "🚀 Starting Xcode Cloud CI setup..."

# Basic environment setup
export LANG=en_US.UTF-8
export FLUTTER_ROOT="$HOME/flutter"

# Navigate to project directory
cd "$CI_PRIMARY_REPOSITORY_PATH" || exit 1
echo "📁 Working directory: $(pwd)"

# Install Flutter
if [ ! -d "$FLUTTER_ROOT" ]; then
  echo "📦 Installing Flutter..."
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$FLUTTER_ROOT"
else
  echo "✅ Flutter already installed, updating..."
  (cd "$FLUTTER_ROOT" && git pull)
fi

export PATH="$FLUTTER_ROOT/bin:$PATH"

# Flutter setup
echo "🔧 Configuring Flutter..."
flutter doctor -v
flutter pub get
flutter precache --ios

# Create environment files (required by pubspec.yaml)
echo "📝 Creating environment files..."
cat > .env.dev << EOF
MOCK_API=true
DISABLE_RATE_LIMIT=true
MAX_REQUESTS_PER_HOUR=500
MAX_REQUESTS_PER_MINUTE=5
FIREBASE_ANALYTICS_ENABLED=false
EOF

cat > .env.prod << EOF
MOCK_API=false
DISABLE_RATE_LIMIT=false
MAX_REQUESTS_PER_HOUR=500
MAX_REQUESTS_PER_MINUTE=5
FIREBASE_ANALYTICS_ENABLED=true
EOF

echo "✅ Environment files created"

# iOS setup - let Flutter handle everything
echo "🍎 Setting up iOS project..."
cd ios || exit 1

# Clean and let Flutter regenerate configuration
rm -rf Pods Podfile.lock .symlinks build

# Let Flutter handle the iOS configuration
cd ..
flutter build ios --config-only --flavor prod -t lib/main_prod.dart

# Install CocoaPods
cd ios
pod install --repo-update

echo "✅ CI setup complete! Ready for build." 