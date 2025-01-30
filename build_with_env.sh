#!/bin/bash
set -e  

# ------------------------------------------------------------------------------
# Script: build_with_env.sh
# ------------------------------------------------------------------------------
# Description:
#   This script automates the process of copying the .env file from the 
#   current project directory to the Dockstation directory, running a 
#   Docker build, and cleaning up the copied .env file on failure.
#
# Usage:
#   1. Place this script somewhere in your $PATH (e.g., /usr/local/bin)
#   2. Run the script from the project directory that contains your .env file
#
# Example:
#   $ build_with_env
#
# Installation:
#   1. Make the script executable:
#      chmod +x build_with_env.sh
#   2. Move it to a directory in your $PATH (e.g., /usr/local/bin for Mac/Linux):
#      mv build_with_env.sh /usr/local/bin/build_with_env
#   3. Run the script from your project directory:
#      build_with_env
#
# How it Works:
#   - Extracts DEV_IMAGE_NAME from the .env file.
#   - Copies .env to Dockstation with a unique name: `.env_DEV_IMAGE_NAME`.
#   - Runs `docker-compose build` using the copied .env file.
#   - Cleans up the copied .env file after a successful build.
#   - If the build fails, it removes the copied file and exits with an error.
# ------------------------------------------------------------------------------

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

# Run Docker Compose Build with the copied .env file
if ! docker-compose --env-file "$ENV_COPY" -f "$DOCKER_COMPOSE_FILE" build vim; then
    echo "❌ Build failed. Cleaning up..."
    rm -f "$ENV_COPY"
    exit 1
fi

# Remove the copied .env file only if the build was successful
echo "✅ Build successful! Cleaning up..."
rm -f "$ENV_COPY"
