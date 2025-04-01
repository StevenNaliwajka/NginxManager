#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
VENV_PATH="$PROJECT_ROOT/venv"

echo "Running NginxDeployer tests..."
echo "Project root: $PROJECT_ROOT"

if [ ! -d "$VENV_PATH" ]; then
  echo "Virtual environment not found at $VENV_PATH"
  echo "Please run setup_venv.sh first."
  exit 1
fi

source "$VENV_PATH/bin/activate"

cd "$PROJECT_ROOT"
pytest "$PROJECT_ROOT/Tests"
