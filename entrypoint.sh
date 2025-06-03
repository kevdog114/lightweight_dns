#!/bin/sh
# entrypoint.sh - Configures and runs dnsmasq with A records from environment variables

# Exit immediately if a command exits with a non-zero status.
set -e

DNSMASQ_ARGS=""
CUSTOM_RECORDS_FOUND=0

echo "INFO: Searching for A_RECORD_* environment variables..."

# Iterate over all environment variables to find A_RECORD_*
# Using printenv and a loop is more robust for various shell environments.
printenv | while IFS='=' read -r var_name var_value; do
  # Check if the variable name starts with A_RECORD_
  case "$var_name" in
    A_RECORD_*)
      # Expected format for var_value: hostname=ip_address
      # Example: A_RECORD_WEB="myapp.local=192.168.1.10"

      # Parse hostname and IP address from var_value
      # Ensure robust parsing, especially if var_value might be malformed.
      hostname=$(echo "$var_value" | cut -d= -f1)
      ip_address=$(echo "$var_value" | cut -d= -f2-) # -f2- gets the rest of the string after the first '='

      if [ -n "$hostname" ] && [ -n "$ip_address" ] && [ "$hostname" != "$var_value" ] && [ "$ip_address" != "$var_value" ]; then
        DNSMASQ_ARGS="$DNSMASQ_ARGS --address=/$hostname/$ip_address"
        echo "INFO: Configuring A record: $hostname -> $ip_address"
        CUSTOM_RECORDS_FOUND=1
      else
        echo "WARN: Malformed or incomplete A_RECORD variable: $var_name=$var_value. Expected format: HOSTNAME=IP_ADDRESS. Skipping."
      fi
      ;;
  esac
done

if [ "$CUSTOM_RECORDS_FOUND" -eq 0 ]; then
  echo "WARN: No A_RECORD_* environment variables found or all were malformed. dnsmasq will start with no custom A records from environment."
fi

# Default dnsmasq options:
# --no-daemon: Run in foreground (essential for Docker containers)
# --log-queries: Log DNS queries to stderr, useful for debugging.
# --log-facility=- : Log to stderr (instead of syslog).
# --no-hosts: Do not load A records from /etc/hosts. We are defining them via --address.
# --no-resolv: Do not read /etc/resolv.conf or other system DNS servers for upstream resolution.
#              This makes dnsmasq authoritative ONLY for the records provided via --address
#              and any other local configurations. It will not forward other queries.
#              If you want forwarding, remove --no-resolv and potentially add --server options
#              (e.g., --server=8.8.8.8 --server=1.1.1.1).
DEFAULT_OPTS="--log-queries --log-facility=- --no-hosts --no-resolv"

echo "INFO: Starting dnsmasq..."
# Execute dnsmasq with the generated arguments and any command arguments passed to the container (from Docker CMD)
# The "$@" allows passing additional dnsmasq flags when running the container.
exec dnsmasq --no-daemon $DEFAULT_OPTS $DNSMASQ_ARGS "$@"
