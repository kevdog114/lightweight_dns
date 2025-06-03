# Dockerfile to run dnsmasq with A records from environment variables

# Use a lightweight base image
FROM alpine:3.19

# Install dnsmasq
# dnsmasq is a lightweight DNS, DHCP and TFTP server.
RUN apk add --no-cache dnsmasq

# Copy the entrypoint script that will configure and run dnsmasq
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

# Make the entrypoint script executable
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose standard DNS ports
EXPOSE 53/udp
EXPOSE 53/tcp

# Set the entrypoint to our custom script
# This script will process environment variables and start dnsmasq
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command for dnsmasq (can be overridden if needed)
# The entrypoint script will pass necessary arguments like --no-daemon.
# Any arguments provided here will be appended after the ones in the entrypoint script.
CMD []
