#!/bin/bash

# Exit on any error
set -e

# Resolve absolute path to this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
VENV_PATH="$PROJECT_ROOT/venv"

echo "Running NginxDeployer tests..."
echo "Project root: $PROJECT_ROOT"

# Ensure virtual environment exists
if [ ! -d "$VENV_PATH" ]; then
  echo "Virtual environment not found at $VENV_PATH"
  echo "Please run setup_venv.sh first."
  exit 1
fi

# Activate virtual environment
source "$VENV_PATH/bin/activate"

# Run pytest from the root (so Codebase/ is importable)
cd "$PROJECT_ROOT"
pytest Tests/
