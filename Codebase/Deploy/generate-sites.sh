#!/bin/bash

set -e

# Get the absolute path of this script's directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Construct absolute paths for the template directory and path.txt
TEMPLATE_DIR="$SCRIPT_DIR/../Codebase/Sites/sites-available"
echo "path is currently $SCRIPT_DIR"
PATH_FILE="$SCRIPT_DIR/../Codebase/Config/path.txt"

# Check for path.txt
if [ ! -f "$PATH_FILE" ]; then
    echo "Error: path.txt not found at $PATH_FILE"
    exit 1
fi

# Read the project path from path.txt, stripping trailing slashes
PROJECT_PATH="$(sed 's:/*$::' < "$PATH_FILE")"

echo "Generating site configs using project path: $PROJECT_PATH"
echo

# Ensure we process *.template if any exist
shopt -s nullglob

# Loop over all *.template files
for template in "$TEMPLATE_DIR"/*.template; do
    base="$(basename "$template" .template)"
    output="$TEMPLATE_DIR/$base"

    echo "Generating: $output"
    # Perform the replacement of {{PROJECT_PATH}} with the actual path
    sed "s|{{PROJECT_PATH}}|$PROJECT_PATH|g" "$template" > "$output"
done

echo
echo "All site templates rendered successfully."
