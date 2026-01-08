#! /bin/bash

# Requirements
if [ $EUID -ne 0 ]; then
  echo "⚠️  Please run the script as root..."
  exit 1
elif [ ! -d "/var/lib/docker" ]; then
  echo "⚠️  Docker is not installed. Please install Docker before running this script..."
  exit 1
elif ! command -v crontab >/dev/null 2>&1; then
  echo "⚠️  Crontab is not installed. Please install Crontab before running this script..."
  exit 1
fi

# Script parameters
if [[ $1 == "--help" ]] || [[ $1 == "-h" ]]; then
  echo "Usage: ./init.sh"
  echo ""
  echo "This script initializes and starts the Upsignon PRO service using Docker."
  echo "Make sure Docker is installed and running before executing this script."
  echo "Options:"
  echo "  -h, --help    Show this help message and exit"
  echo "  -le           [REQUIRED] Specify to use Let's Encrypt for TLS certificates"
  echo "  -certs        [REQUIRED] Specify to use custom TLS certificates"
  exit 0
elif [[ $1 == "-le" ]]; then
  echo "Using Let's Encrypt for TLS certificates..."
  SSL=le
elif [[ $1 == "-certs" ]]; then
  echo "Using custom TLS certificates..."
  SSL=certs
elif [[ $1 != "-le" ]] && [[ $1 != "-certs" ]]; then
  echo "Invalid argument. Use --help or -h for usage information."
  exit 1
fi

# Absolute path of this script's directory
DOCKER_DIR="$(dirname "$(realpath ${BASH_SOURCE[0]})")" && cd $DOCKER_DIR

# Prepare environment
SESSION_SECRET=$(openssl rand -hex 30)
sed -i "s/SESSION_SECRET.*/SESSION_SECRET=$SESSION_SECRET/" .env

# Generate Traefik TLS configuration if using custom certificates
if [[ $SSL == "certs" ]]; then

  # Check for .crt files in the certs directory
  shopt -s nullglob && CERTS=($SSL/*.crt)
  if [[ $CERTS ]]; then
    CERT_FILE=$SSL/tls.yml
    echo -e "tls:\n  certificates:" > $CERT_FILE

    # Add each certificate and its corresponding key to the TLS configuration
    for cert in ${CERTS[@]}; do
      key="${cert%.crt}.key"; if [[ -f $key ]]; then
        echo "    - certFile: /$cert" >> $CERT_FILE
        echo "      keyFile: /$key" >> $CERT_FILE
      else
        echo "❌ No $key file found in the $SSL directory. Please add your private key before proceeding. Script stopped."
        exit 1
      fi
    done
    echo "✅ Traefik TLS configuration generated at $CERT_FILE"
  else
    echo "❌ No .crt files found in the $SSL directory. Please add your TLS certificates before proceeding. Script stopped."
    exit 1
  fi
fi

# Start Upsignon PRO service
echo "🚀 Start Upsignon PRO service..."
if docker compose -f docker-compose-$SSL.yml up -d; then

  # Wait for the service to be ready
  echo "⏳ Initializing services..."
  source .env
  while ! docker logs uso.dashboard 2>&1 | grep -q "port: $DASHBOARD_PORT"; do
      echo "⏳ Waiting for services to start ..."
      sleep 30
  done
  echo "✅ Upsignon PRO service started successfully."

  # Create the Super Admin
  SA_URL=$(docker exec -it uso.dashboard node /app/upsignon-pro-dashboard/back/scripts/addSuperAdmin.js | tail -n 1)
  echo "✅ Temporary super admin created. Open this link to access the dashboard. This link will be valid for 5 minutes: $SA_URL"

  # Setup automatic code updates via cron
  UPDATE_SCRIPT="$DOCKER_DIR/scripts/update.sh -$SSL"
  (crontab -l 2>/dev/null | grep -v "$UPDATE_SCRIPT"; echo "0 1 * * * $UPDATE_SCRIPT") | crontab -
  echo "✅ Automatic updates have been scheduled via cron."
else
  echo "❌ Failed to start Upsignon PRO service. Script stopped."
  exit 1
fi
