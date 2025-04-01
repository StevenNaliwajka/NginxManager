#!/bin/bash

# Exit on error
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
VENV_PATH="$PROJECT_ROOT/venv"

echo "Running NginxDeployer tests..."

# Ensure venv exists
if [ ! -d "$VENV_PATH" ]; then
  echo "Virtual environment not found at $VENV_PATH"
  echo "Please run setup_venv.sh first."
  exit 1
fi

# Activate venv
source "$VENV_PATH/bin/activate"

# Run pytest from the project root, targeting the Tests directory
cd "$PROJECT_ROOT"
pytest Tests/
