#!/bin/bash
set -e  

# ------------------------------------------------------------------------------
# Script: build_with_env.sh
# ------------------------------------------------------------------------------
# Description:
#   Automates building and running Dockstation services.
#
# Usage:
#   $ build_with_env.sh build    # Build Vim service
#   $ build_with_env.sh run      # Run Vim service
#
# Installation:
#   1. Make the script executable:
#      chmod +x build_with_env.sh
#   2. Move it to $PATH:
#      mv build_with_env.sh /usr/local/bin/build_with_env
#  How it Works:
#   - Extracts DEV_IMAGE_NAME from the .env file.
#   - Copies .env to Dockstation with a unique name: `.env_DEV_IMAGE_NAME`.
#   - Runs `docker-compose build` using the copied .env file.
#   - Cleans up the copied .env file after a successful build.
#   - If the build fails, it removes the copied file and exits with an error.
# ------------------------------------------------------------------------------

# Ensure a command is provided (build or run)
COMMAND="${1:-}"
if [[ -z "$COMMAND" ]]; then
    echo "❌ ERROR: No command provided. Use 'build' or 'run'."
    exit 1
fi

# Get the current directory where the script is executed
HOST_APP_DIR="$PWD"
HOST_ENV_FILE="$HOST_APP_DIR/.env"

# Define Dockstation directory and paths
DOCKSTATION_DIR="/Users/rohailtaimour/home/2_AREAS/work/dockstation"
DOCKER_COMPOSE_FILE="$DOCKSTATION_DIR/docker-compose.yml"

# Check if .env file exists in the current directory
if [[ ! -f "$HOST_ENV_FILE" ]]; then
    echo "❌ ERROR: No .env file found in $HOST_APP_DIR"
    exit 1
fi
 

# Extract DEV_IMAGE_NAME from .env file
DEV_IMAGE_NAME=$(grep "^DEV_IMAGE_NAME=" "$HOST_ENV_FILE" | cut -d '=' -f2 | tr -d '"')

# If DEV_IMAGE_NAME is empty, fail
if [[ -z "$DEV_IMAGE_NAME" ]]; then
    echo "❌ ERROR: DEV_IMAGE_NAME not found in .env"
    exit 1
fi

# Generate a unique filename based on DEV_IMAGE_NAME
ENV_COPY="$DOCKSTATION_DIR/.env_$DEV_IMAGE_NAME"

# Change directory to Dockstation
cd "$DOCKSTATION_DIR" || { echo "❌ ERROR: Failed to change directory to $DOCKSTATION_DIR"; exit 1; }

# Copy .env file to Dockstation with a unique name
cp "$HOST_ENV_FILE" "$ENV_COPY"

echo "✅ Copied .env file to: $ENV_COPY"

# Perform the requested command
if [[ "$COMMAND" == "build" ]]; then
    echo "🚀 Building Vim Service..."
    if ! docker-compose --env-file "$ENV_COPY" -f "$DOCKER_COMPOSE_FILE" build vim; then
        echo "❌ Build failed. Cleaning up..."
        rm -f "$ENV_COPY"
        exit 1
    fi
else 
    echo "🚀 Running Vim Service..."
    if ! docker-compose --env-file "$ENV_COPY" -f "$DOCKER_COMPOSE_FILE" run --rm vim; then
        echo "❌ Run failed. Cleaning up..."
        rm -f "$ENV_COPY"
        exit 1
    fi
fi

# Remove the copied .env file only if the build was successful
echo "✅ Build successful! Cleaning up..."
rm -f "$ENV_COPY"
