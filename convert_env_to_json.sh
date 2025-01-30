#!/bin/bash
set -euo pipefail  # Enable strict error handling

# Ensure an input file is provided
if [[ -z "${1:-}" ]]; then
    echo "❌ ERROR: No .env file specified!"
    exit 1
fi

ENV_FILE="$1"
JSON_OUTPUT="${2:-/tmp/env.json}"

# Ensure .env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ ERROR: .env file not found at $ENV_FILE!"
    exit 1
fi

echo "{" > "$JSON_OUTPUT"

# Read .env file, ignore comments and blank lines
grep -v '^#' "$ENV_FILE" | grep -v '^\s*$' | while IFS='=' read -r key value
do
    # Skip malformed lines (no '=' present)
    if [[ -z "$key" || -z "$value" ]]; then
        continue
    fi

    # Remove surrounding quotes if present
    value=$(echo "$value" | sed -E 's/^"(.*)"$/\1/')

    # Escape double quotes in values
    value=$(echo "$value" | sed 's/"/\\"/g')

    # Normalize Windows paths to Unix format if detected
    if [[ "$value" =~ ^[A-Za-z]:\\ ]]; then
        value=$(echo "$value" | sed -E 's#\\#/#g' | sed -E 's#([A-Za-z]):#/mnt/\L\1#g')
    fi

    # Print in JSON format
    echo "  \"$key\": \"$value\"," >> "$JSON_OUTPUT"
done

# Remove trailing comma and close JSON object
sed -i '$ s/,$//' "$JSON_OUTPUT" || sed -i '' '$ s/,$//' "$JSON_OUTPUT"
echo "}" >> "$JSON_OUTPUT"

# Validate JSON output
if ! jq empty "$JSON_OUTPUT" >/dev/null 2>&1; then
    echo "❌ ERROR: Invalid JSON generated!"
    cat "$JSON_OUTPUT"
    exit 1
fi

echo "✅ .env converted to JSON ($JSON_OUTPUT)"
