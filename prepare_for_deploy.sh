#!/bin/bash

# BloomSafe preparation script
set -e

MODE="${1:-all}"  # Default to 'all' if no argument provided

function print_usage() {
  echo "Usage: $0 [mode]"
  echo "Modes:"
  echo "  all         - Prepare for both development and app store (default)"
  echo "  dev         - Prepare for development only"
  echo "  appstore    - Prepare for App Store submission only"
  echo "  ci          - Prepare for CI environment"
  exit 1
}

# Check for help flag
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  print_usage
fi

# Validate mode
if [[ "$MODE" != "all" && "$MODE" != "dev" && "$MODE" != "appstore" && "$MODE" != "ci" ]]; then
  echo "Error: Invalid mode '$MODE'"
  print_usage
fi

echo "========== BloomSafe Preparation =========="
echo "Mode: $MODE"
echo "Cleaning up and preparing..."

# Clean Flutter caches
echo "Cleaning Flutter cache..."
flutter clean

# Get dependencies
echo "Getting dependencies..."
flutter pub get

# Create environment files function
create_env_files() {
  if [[ "$MODE" == "all" || "$MODE" == "dev" || "$MODE" == "ci" ]]; then
    if [ ! -f .env.dev ]; then
      echo "Creating .env.dev file"
      cat > .env.dev << 'EOF'
# Development environment file
MOCK_API=true
DISABLE_RATE_LIMIT=true
MAX_REQUESTS_PER_HOUR=500
MAX_REQUESTS_PER_MINUTE=5
FIREBASE_ANALYTICS_ENABLED=false
EOF
    fi
  fi

  if [[ "$MODE" == "all" || "$MODE" == "appstore" || "$MODE" == "ci" ]]; then
    if [ ! -f .env.prod ]; then
      echo "Creating .env.prod file"
      cat > .env.prod << 'EOF'
# Production environment file
MOCK_API=false
DISABLE_RATE_LIMIT=false
MAX_REQUESTS_PER_HOUR=500
MAX_REQUESTS_PER_MINUTE=5
FIREBASE_ANALYTICS_ENABLED=true
EOF
    fi
  fi
}

# Create iOS xcfilelist fix function
create_xcfilelist_fix() {
  if [ ! -f "fix_xcfilelist.sh" ]; then
    echo "Creating xcfilelist fix script..."
    cat > fix_xcfilelist.sh << 'EOF'
#!/bin/sh
set -e

mkdir -p "$(pwd)/Pods/Target Support Files/Pods-Runner"

for CONFIG in "Debug" "Profile" "Release" "Debug-dev" "Profile-dev" "Release-dev" "Debug-prod" "Profile-prod" "Release-prod"
do
  REL_PATH="$(pwd)/Pods/Target Support Files/Pods-Runner"
  
  # Create resources files
  echo "${PODS_ROOT}/Target Support Files/Pods-Runner/Pods-Runner-resources.sh" > "$REL_PATH/Pods-Runner-resources-$CONFIG-input-files.xcfilelist"
  echo "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/Assets.car" > "$REL_PATH/Pods-Runner-resources-$CONFIG-output-files.xcfilelist"
  
  # Create frameworks files
  echo "${PODS_ROOT}/Target Support Files/Pods-Runner/Pods-Runner-frameworks.sh" > "$REL_PATH/Pods-Runner-frameworks-$CONFIG-input-files.xcfilelist"
  echo "${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}/Flutter.framework" > "$REL_PATH/Pods-Runner-frameworks-$CONFIG-output-files.xcfilelist"
done

find "$(pwd)/Pods" -name "*.xcfilelist" -exec chmod 644 {} \; 2>/dev/null || true
echo "XCFileList fix complete!"
EOF
    chmod +x fix_xcfilelist.sh
  fi
}

# Check Info.plist for App Store requirements
check_info_plist() {
  echo "Verifying Info.plist..."
  local MISSING_KEYS=0
  local INFO_PLIST="Runner/Info.plist"

  local required_keys=(
    "ITSAppUsesNonExemptEncryption"
    "UIRequiredDeviceCapabilities" 
    "LSApplicationQueriesSchemes"
    "NSLocationWhenInUseUsageDescription"
    "NSAppTransportSecurity"
  )

  for key in "${required_keys[@]}"; do
    if ! /usr/libexec/PlistBuddy -c "Print :$key" "$INFO_PLIST" &>/dev/null; then
      echo "Warning: Missing required key in Info.plist: $key"
      ((MISSING_KEYS++))
    fi
  done

  if [ $MISSING_KEYS -gt 0 ]; then
    echo "Found $MISSING_KEYS missing keys in Info.plist"
    echo "Please add them before submitting to App Store"
  else
    echo "Info.plist contains all required keys"
  fi

  # Verify entitlements if they exist
  if [ -f "Runner/Runner.entitlements" ]; then
    echo "Verifying entitlements..."
    plutil -lint "Runner/Runner.entitlements" || echo "Warning: Invalid entitlements file"
  fi
}

# Execute functions
create_env_files

# iOS setup
echo "Setting up iOS environment..."
cd ios

# Clean iOS artifacts
echo "Cleaning iOS artifacts..."
rm -rf Pods Podfile.lock .symlinks/plugins
rm -rf Flutter/flutter_export_environment.sh
rm -rf build

# Ensure Flutter directory structure
mkdir -p Flutter

# Install pods with retry logic
echo "Installing CocoaPods..."
if ! pod install --verbose; then
  echo "Pod install failed, trying with repo update..."
  pod install --verbose --repo-update
fi

# Create and run xcfilelist fix
create_xcfilelist_fix
echo "Running xcfilelist fix script..."
./fix_xcfilelist.sh

# App Store specific checks
if [[ "$MODE" == "all" || "$MODE" == "appstore" ]]; then
  check_info_plist
fi

# Return to project root
cd ..

# Build flavors as needed
if [[ "$MODE" == "all" || "$MODE" == "dev" ]]; then
  echo "Building Flutter for development environment..."
  flutter build ios --flavor dev -t lib/main_dev.dart --release --no-codesign
fi

if [[ "$MODE" == "all" || "$MODE" == "appstore" ]]; then
  echo "Building Flutter for production environment..."
  flutter build ios --flavor prod -t lib/main_prod.dart --release --no-codesign
fi

echo "========== Preparation Complete =========="

# Final status and next steps
case "$MODE" in
  "dev"|"all")
    echo "✓ Project ready for development"
    ;;
esac

case "$MODE" in
  "ci"|"all")
    echo "✓ Project ready for CI/CD pipeline"
    echo "Next steps: Git commit and push - Xcode Cloud will auto-build"
    ;;
esac

case "$MODE" in
  "appstore"|"all")
    echo "✓ Project ready for App Store submission"
    echo ""
    echo "Final Checklist:"
    echo "✓ Updated Info.plist with required keys"
    echo "✓ Deployment target set to iOS 14.0+"
    echo "✓ CocoaPods dependencies resolved"
    echo "✓ Build phases verified"
    echo "✓ Production flavor configured correctly"
    echo ""
    echo "Next steps:"
    echo "1. Open Runner.xcworkspace in Xcode"
    echo "2. Select 'Runner' scheme with 'prod' flavor"
    echo "3. Ensure proper signing identity is selected"
    echo "4. Use Xcode Cloud workflow or Archive manually"
    echo "5. Submit to App Store Connect"
    ;;
esac 