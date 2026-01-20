#! /bin/bash

# Requirements
if [ $EUID -ne 0 ]; then
  echo "⚠️  Please run the script as root..."
  exit 1
elif [ ! -d "/var/lib/docker" ]; then
  echo "⚠️  Docker is not installed. Please install Docker before running this script..."
  exit 1
fi

# Log function
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') | $1" | tee -a "$LOG_FILE"
}

# Script parameters
if [[ $1 == "--help" ]] || [[ $1 == "-h" ]]; then
  log "Usage: ./init.sh"
  log ""
  log "This script initializes and starts the Upsignon Pro application using Docker."
  log "Make sure Docker is installed and running before executing this script."
  log "Options:"
  log "  -h, --help    Show this help message and exit"
  log "  -le           [REQUIRED] Specify to use Let's Encrypt for TLS certificates"
  log "  -certs        [REQUIRED] Specify to use custom TLS certificates"
  exit 0
elif [[ $1 == "-le" ]]; then
  log "Using Let's Encrypt for TLS certificates..."
  SSL=le
elif [[ $1 == "-certs" ]]; then
  log "Using custom TLS certificates..."
  SSL=certs
elif [[ $1 != "-le" ]] && [[ $1 != "-certs" ]]; then
  log "Invalid argument. Use --help or -h for usage information."
  exit 1
fi

# Absolute path of this script's directory
DOCKER_DIR="$(dirname "$(realpath ${BASH_SOURCE[0]})" | sed 's|\(/docker\).*|\1|')" && cd $DOCKER_DIR
LOG_FILE="$DOCKER_DIR/update.log"

# Update the local repository
log "⏳ Updating the UpSignOn PRO docker service repository..."
git fetch origin main
git reset --hard origin/main

# Update & Restart UpSignOn PRO service
log "🚀 Updating & restarting UpSignOn PRO service..."
if docker compose -f docker-compose-$SSL.yml up -d ; then
  log "✅ UpSignOn PRO service has been updated and restarted successfully."
else
  log "❌ Failed to restart UpSignOn PRO service. Script stopped."
  exit 1
fi

