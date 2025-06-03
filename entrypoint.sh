#!/bin/sh
# entrypoint.sh - Configures and runs dnsmasq with A records from a single environment variable

# Exit immediately if a command exits with a non-zero status.
set -e

# DNSMASQ_A_RECORDS_ARGS will be taken directly from the environment variable.
# Example: DNSMASQ_A_RECORDS_ARGS="--address=/myapp.local/192.168.1.100 --address=/service.dev/10.0.0.5"
# The user is responsible for formatting this string correctly.
CUSTOM_A_RECORD_ARGS="${DNSMASQ_A_RECORDS_ARGS}" # Use the value of DNSMASQ_A_RECORDS_ARGS env var

if [ -n "$CUSTOM_A_RECORD_ARGS" ]; then
  echo "INFO: Using custom A record arguments from DNSMASQ_A_RECORDS_ARGS: $CUSTOM_A_RECORD_ARGS"
else
  echo "INFO: No DNSMASQ_A_RECORDS_ARGS environment variable set. dnsmasq will start with no custom A records from this variable."
fi

# Default dnsmasq options:
# --no-daemon: Run in foreground (essential for Docker containers)
# --log-queries: Log DNS queries to stderr, useful for debugging.
# --log-facility=- : Log to stderr (instead of syslog).
# --no-hosts: Do not load A records from /etc/hosts.
# --no-resolv: Do not read /etc/resolv.conf or other system DNS servers for upstream resolution.
#              This makes dnsmasq authoritative ONLY for the records provided.
#              If you want forwarding, remove --no-resolv and potentially add --server options
#              (e.g., --server=8.8.8.8 --server=1.1.1.1).
# --listen-address=0.0.0.0: Listen on all interfaces within the container.
# --local-service: Accept DNS queries from any interface it's listening on.
DEFAULT_OPTS="--log-queries --log-facility=- --no-hosts --no-resolv --listen-address=0.0.0.0 --local-service"

echo "INFO: Starting dnsmasq..."
# Execute dnsmasq with the default options, custom A record arguments, and any command arguments passed to the container.
# CUSTOM_A_RECORD_ARGS is intentionally not quoted to allow word splitting by the shell,
# so each --address=/.../... part is treated as a separate argument.
# "$@" allows passing additional dnsmasq flags when running the container.
exec dnsmasq --no-daemon $DEFAULT_OPTS $CUSTOM_A_RECORD_ARGS "$@"
