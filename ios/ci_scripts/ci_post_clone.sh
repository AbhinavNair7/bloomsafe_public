#!/bin/sh

# Enable full error reporting
set -ex

# Environment setup
export LANG=en_US.UTF-8
export FLUTTER_ROOT="$HOME/flutter"

# Navigate to project directory
cd "$CI_PRIMARY_REPOSITORY_PATH" || exit 1

echo "Current directory: $(pwd)"
echo "Setting up for App Store submission..."

# Install Flutter (stable channel, optimized for CI)
if [ ! -d "$FLUTTER_ROOT" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$FLUTTER_ROOT"
else
  echo "Flutter already installed at $FLUTTER_ROOT, skipping clone"
  # Update Flutter instead of cloning
  (cd "$FLUTTER_ROOT" && git pull)
fi
export PATH="$FLUTTER_ROOT/bin:$PATH"

# Flutter verification and dependencies
flutter doctor -v
flutter pub get
flutter precache --ios

# Create environment files required by pubspec.yaml assets
echo "Creating environment files for CI build..."

# Validate required environment variables for production build
if [ -z "$AIRNOW_API_KEY" ]; then
  echo "⚠️  WARNING: AIRNOW_API_KEY not set in Xcode Cloud environment variables"
  echo "   App Store reviewers may encounter 'API key not available' error"
  echo "   Please add AIRNOW_API_KEY to your Xcode Cloud environment variables"
fi

# Create .env.dev (required by pubspec.yaml assets, even in CI)
cat > .env.dev << EOF
# Development environment file for CI builds
# Uses mock API to avoid consuming quota during development
MOCK_API=true
DISABLE_RATE_LIMIT=true
MAX_REQUESTS_PER_HOUR=500
MAX_REQUESTS_PER_MINUTE=5
FIREBASE_ANALYTICS_ENABLED=false
EOF

# Create .env.prod (primary environment for CI builds)
cat > .env.prod << EOF
# Production environment file for CI builds
# Real API mode with production configuration
MOCK_API=false
DISABLE_RATE_LIMIT=false
MAX_REQUESTS_PER_HOUR=500
MAX_REQUESTS_PER_MINUTE=5
FIREBASE_ANALYTICS_ENABLED=true
AIRNOW_API_KEY=${AIRNOW_API_KEY}
EOF

echo "Environment files created successfully"
# Only show file existence, not contents (to avoid logging sensitive data)
ls -la .env.dev .env.prod

# Clean iOS artifacts
cd ios || exit 1
rm -rf Pods Podfile.lock .symlinks

# Ensure Flutter directory exists
mkdir -p Flutter

# Create Generated.xcconfig with minimum required content
cat > Flutter/Generated.xcconfig << EOF
// This is a generated file; do not edit or check into version control.
FLUTTER_ROOT=$FLUTTER_ROOT
FLUTTER_APPLICATION_PATH=$CI_PRIMARY_REPOSITORY_PATH
COCOAPODS_PARALLEL_CODE_SIGN=true
FLUTTER_TARGET=lib/main_prod.dart
FLUTTER_BUILD_DIR=build
FLUTTER_BUILD_NAME=1.0.0
FLUTTER_BUILD_NUMBER=1
EXCLUDED_ARCHS[sdk=iphonesimulator*]=arm64
EOF

# Ensure all necessary flavor xcconfig files exist
for FLAVOR in dev prod; do
  for CONFIG in Debug Profile Release; do
    LOWCONFIG=$(echo "$CONFIG" | tr '[:upper:]' '[:lower:]')
    
    # Common configuration
    DISPLAY_NAME="BloomSafe"
    BUNDLE_NAME="BloomSafe"
    
    # Set dev-specific names
    if [ "$FLAVOR" = "dev" ]; then
      DISPLAY_NAME="${DISPLAY_NAME} Dev"
      BUNDLE_NAME="${BUNDLE_NAME} Dev"
    fi
    
    # Create the config file
    cat > "Flutter/${FLAVOR}${CONFIG}.xcconfig" << EOF
#include? "Pods/Target Support Files/Pods-Runner/Pods-Runner.${LOWCONFIG}.xcconfig"
#include? "Generated.xcconfig"

ASSET_PREFIX=${FLAVOR}
BUNDLE_NAME=${BUNDLE_NAME}
BUNDLE_DISPLAY_NAME=${DISPLAY_NAME}
FLUTTER_TARGET=lib/main_${FLAVOR}.dart
FLUTTER_BUILD_MODE=${LOWCONFIG}
EOF
  done
done

# Install pods
pod install --verbose || pod install --verbose --repo-update

# Create xcfilelist fix script
cat > fix_xcfilelist.sh << EOF
#!/bin/sh

# Script to fix xcfilelist issues during build
set -ex

# Create Target Support Files directory
mkdir -p "\$(pwd)/Pods/Target Support Files/Pods-Runner"

# Create all necessary xcfilelist files for all configurations
for CONFIG in "Debug" "Profile" "Release" "Debug-dev" "Profile-dev" "Release-dev" "Debug-prod" "Profile-prod" "Release-prod"
do
  # Path to create files
  REL_PATH="\$(pwd)/Pods/Target Support Files/Pods-Runner"
  
  # Create resources files
  RESOURCES_INPUT="\$REL_PATH/Pods-Runner-resources-\$CONFIG-input-files.xcfilelist"
  echo "\${PODS_ROOT}/Target Support Files/Pods-Runner/Pods-Runner-resources.sh" > "\$RESOURCES_INPUT"
  
  RESOURCES_OUTPUT="\$REL_PATH/Pods-Runner-resources-\$CONFIG-output-files.xcfilelist"
  echo "\${TARGET_BUILD_DIR}/\${UNLOCALIZED_RESOURCES_FOLDER_PATH}/Assets.car" > "\$RESOURCES_OUTPUT"
  
  # Create frameworks files
  FRAMEWORKS_INPUT="\$REL_PATH/Pods-Runner-frameworks-\$CONFIG-input-files.xcfilelist"
  echo "\${PODS_ROOT}/Target Support Files/Pods-Runner/Pods-Runner-frameworks.sh" > "\$FRAMEWORKS_INPUT"
  
  FRAMEWORKS_OUTPUT="\$REL_PATH/Pods-Runner-frameworks-\$CONFIG-output-files.xcfilelist"
  echo "\${TARGET_BUILD_DIR}/\${FRAMEWORKS_FOLDER_PATH}/Flutter.framework" > "\$FRAMEWORKS_OUTPUT"
done

# Fix permissions
find "\$(pwd)/Pods" -name "*.xcfilelist" -exec chmod 644 {} \; 2>/dev/null || true

echo "XCFileList fix complete!"
EOF

# Make fix script executable
chmod +x fix_xcfilelist.sh

# Run the fix script
./fix_xcfilelist.sh

# Update deployment target to 14.0 in project.pbxproj if needed
ruby -e '
require "xcodeproj"
project_path = "Runner.xcodeproj"
project = Xcodeproj::Project.open(project_path)
project.targets.each do |target|
  target.build_configurations.each do |config|
    if config.build_settings["IPHONEOS_DEPLOYMENT_TARGET"].to_f < 14.0
      puts "Updating #{target.name} #{config.name} deployment target to 14.0"
      config.build_settings["IPHONEOS_DEPLOYMENT_TARGET"] = "14.0"
    end
  end
end
project.save
' || echo "Failed to update deployment target, please check manually"

# Return to project root and build production flavor
cd ..

# Verify environment files are in place for Flutter build
echo "Verifying environment files for Flutter build..."
if [ -f .env.dev ] && [ -f .env.prod ]; then
  echo "✓ Environment files ready"
  ls -la .env.dev .env.prod
else
  echo "✗ Required environment files missing"
  ls -la .env* 2>/dev/null || echo "No .env files found"
  exit 1
fi

# Build with verbose output to debug any remaining issues
echo "Starting Flutter build for production..."
flutter build ios --flavor prod -t lib/main_prod.dart --release --no-codesign --verbose 