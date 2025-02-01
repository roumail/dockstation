#!/bin/bash
set -euo pipefail  # Strict error handling

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

# Read .env file, ignoring comments and blank lines
while IFS='=' read -r key value || [[ -n "$key" ]]; do
    # Trim whitespace
    key=$(echo "$key" | xargs)
    value=$(echo "$value" | xargs)

    # Skip empty keys (malformed lines)
    if [[ -z "$key" || "$key" =~ ^# || -z "$value" ]]; then
        continue
    fi

    # Remove surrounding quotes
    value=$(echo "$value" | sed -E 's/^"(.*)"$/\1/')

    # Escape double quotes in values
    value=${value//\"/\\\"}

    # Normalize Windows paths (C:\ -> /mnt/c/)
    if [[ "$value" =~ ^[A-Za-z]:\\ ]]; then
        value=$(echo "$value" | sed -E 's#\\#/#g' | sed -E 's#([A-Za-z]):#/mnt/\L\1#g')
    fi

    # Append JSON entry
    echo "  \"$key\": \"$value\"," >> "$JSON_OUTPUT"
done < "$ENV_FILE"

# Remove trailing comma (cross-platform safe)
truncate -s-2 "$JSON_OUTPUT"
echo -e "\n}" >> "$JSON_OUTPUT"

# Validate JSON output
if ! jq empty "$JSON_OUTPUT" >/dev/null 2>&1; then
    echo "❌ ERROR: Invalid JSON generated!"
    cat "$JSON_OUTPUT"
    exit 1
fi

echo "✅ .env converted to JSON ($JSON_OUTPUT)"
