#!/bin/sh
# entrypoint.sh - Configures and runs dnsmasq with A records from environment variables

# Exit immediately if a command exits with a non-zero status.
set -e

DNSMASQ_ARGS=""
# We will check if DNSMASQ_ARGS is non-empty later.

echo "Lightweight DNS v2"
echo "INFO: Searching for A_RECORD_* environment variables..."

# Generate all potential arguments. Each valid --address will be on a new line.
# Logs (INFO/WARN) go to stderr and are displayed immediately.
# Valid --address arguments go to stdout and are captured by GENERATED_ARGS.
GENERATED_ARGS=$(printenv | while IFS='=' read -r var_name var_value; do
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
        echo "--address=/$hostname/$ip_address" # Output argument to STDOUT
        echo "INFO: Configuring A record: $hostname -> $ip_address" >&2 # Log to STDERR
      else
        echo "WARN: Malformed or incomplete A_RECORD variable: $var_name=$var_value. Expected format: HOSTNAME=IP_ADDRESS. Skipping." >&2 # Log to STDERR
      fi
      ;;
  esac
done) # End of command substitution for GENERATED_ARGS

# Now, process the captured arguments to build DNSMASQ_ARGS.
# This loop runs in the current shell.
if [ -n "$GENERATED_ARGS" ]; then
  # Use echo and pipe to the while loop for POSIX compatibility
  echo "$GENERATED_ARGS" | while IFS= read -r arg_line; do
    # Each line in GENERATED_ARGS should be a valid --address argument.
    # We append it to DNSMASQ_ARGS, ensuring a space separator.
    # The initial space in "$DNSMASQ_ARGS $arg_line" is intentional if DNSMASQ_ARGS is empty,
    # dnsmasq handles leading/multiple spaces in its arguments gracefully.
    # If DNSMASQ_ARGS is already populated, it adds a space before the new argument.
    DNSMASQ_ARGS="$DNSMASQ_ARGS $arg_line"
  done
fi

echo "DNSMASQ_ARGS: '$DNSMASQ_ARGS'"

# Check if any arguments were added to DNSMASQ_ARGS
if [ -z "$DNSMASQ_ARGS" ]; then # -z checks if the string is empty
  echo "WARN: No valid A_RECORD_* environment variables found or all were malformed. dnsmasq will start with no custom A records from environment."
else
  echo "INFO: Custom A records have been configured."
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
# --listen-address=0.0.0.0: Listen on all interfaces within the container.
# --local-service: Accept DNS queries from any interface it's listening on.
DEFAULT_OPTS="--log-queries --log-facility=- --no-hosts --no-resolv --listen-address=0.0.0.0 --local-service"

echo "INFO: Starting dnsmasq with arguments: $DEFAULT_OPTS$DNSMASQ_ARGS $@" # Note: DNSMASQ_ARGS will have a leading space if not empty
# Execute dnsmasq with the generated arguments and any command arguments passed to the container (from Docker CMD)
# The "$@" allows passing additional dnsmasq flags when running the container.
# Using $DNSMASQ_ARGS without quotes allows word splitting for the arguments.
exec dnsmasq --no-daemon $DEFAULT_OPTS $DNSMASQ_ARGS "$@"
