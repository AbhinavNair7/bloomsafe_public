#!/bin/bash

# Script to run the BloomSafe app in production mode
# Usage: ./scripts/run_prod.sh [device_id] [mode]
# mode can be: debug (default), profile, or release

# Show current directory and app details
echo "=============================================="
echo "Running BloomSafe in Production Mode"
echo "=============================================="

# Determine run mode
MODE=${2:-debug}
echo "Run mode: $MODE"

# Build the run command based on mode
RUN_CMD="flutter run --flavor prod -t lib/main_prod.dart"
if [ "$MODE" == "profile" ]; then
  RUN_CMD="$RUN_CMD --profile"
elif [ "$MODE" == "release" ]; then
  RUN_CMD="$RUN_CMD --release"
fi

# Check if a specific device ID was provided
if [ -n "$1" ]; then
  echo "Using device: $1"
  $RUN_CMD -d "$1"
else
  # No device specified, let Flutter choose or prompt
  echo "Using default or available device"
  $RUN_CMD
fi

# Script completed
echo "=============================================="
echo "Prod run script completed"
echo "==============================================" 