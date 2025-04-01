#!/bin/bash

# Exit on error
set -e

# Get the script's directory (./Codebase/Tests)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
VENV_PATH="$PROJECT_ROOT/venv"

echo "Running NginxDeployer tests..."

# Check virtual environment
if [ ! -d "$VENV_PATH" ]; then
  echo "Error: Virtual environment not found at $VENV_PATH"
  echo "Run setup_venv.sh first."
  exit 1
fi

# Activate venv
source "$VENV_PATH/bin/activate"

# Run pytest against the Tests directory
cd "$SCRIPT_DIR"
pytest .

# Return to original directory (optional)
cd -
