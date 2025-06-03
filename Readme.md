Custom DNS Server with dnsmasq (Dockerized)
This project provides a Docker image that runs dnsmasq as a simple DNS server. You can define custom DNS A records by passing environment variables to the Docker container when it starts.

This is useful for local development, testing, or creating simple DNS resolution within a Docker network.

Features
Lightweight: Based on Alpine Linux and dnsmasq.

Custom A Records: Define A records easily using environment variables.

Configurable: dnsmasq options can be extended.

Logging: DNS queries are logged to stderr for easy debugging.

Prerequisites
Docker installed and running on your system.

Files
Dockerfile: Defines the Docker image.

entrypoint.sh: A script that reads environment variables to configure dnsmasq A records and then starts the dnsmasq service.

Building the Docker Image
Clone the repository or save the files:
Ensure Dockerfile and entrypoint.sh are in the same directory.

Build the image:
Open your terminal, navigate to the directory containing the files, and run:

docker build -t my-custom-dns .

You can replace my-custom-dns with any image name you prefer.

Running the Container
To run the container, use the docker run command. You will need to:

Publish the DNS ports (53/udp and 53/tcp).

Define your A records using environment variables prefixed with A_RECORD_. The value of each variable must be in the format hostname=ip_address.

Example:

To create A records for service1.local pointing to 192.168.0.100 and webapp.dev pointing to 10.0.0.5:

docker run -d --name dns-server \
  -p 53:53/udp \
  -p 53:53/tcp \
  -e A_RECORD_SERVICE1="service1.local=192.168.0.100" \
  -e A_RECORD_WEBAPP="webapp.dev=10.0.0.5" \
  -e A_RECORD_ANOTHER_HOST="another.example.com=172.16.0.10" \
  my-custom-dns

Explanation of docker run options:

-d: Run the container in detached mode (in the background).

--name dns-server: Assign a name to the container for easier management.

-p 53:53/udp -p 53:53/tcp: Map port 53 on the host to port 53 in the container for both UDP and TCP protocols (standard DNS ports).

-e A_RECORD_...="hostname=ip_address": Define an environment variable for each A record.

The variable name must start with A_RECORD_.

The value must be in the format hostname=ip_address.

my-custom-dns: The name of the Docker image you built.

Testing the DNS Server
You can test if the DNS server is working correctly using tools like dig or nslookup.

Using dig (assuming the container is running on the same machine):

dig @localhost service1.local
# Expected output will include an A record for service1.local with IP 192.168.0.100

dig @localhost webapp.dev
# Expected output will include an A record for webapp.dev with IP 10.0.0.5

If you are testing from another machine or container, replace localhost with the IP address of the Docker host where the dns-server container is running.

If testing from another Docker container, you can use the --dns <ip_of_dns_container> option when running that container, or connect it to the same Docker network and use the dns-server container's name or IP.

Configuration
DNS Forwarding

By default, this dnsmasq instance is configured with --no-resolv, meaning it will only resolve the A records you explicitly define via environment variables. It will not forward other DNS queries (e.g., for google.com) to upstream DNS servers.

If you want the container to also act as a caching DNS forwarder:

Modify entrypoint.sh:
Remove or comment out --no-resolv from the DEFAULT_OPTS variable.

# In entrypoint.sh
# DEFAULT_OPTS="--log-queries --log-facility=- --no-hosts --no-resolv"
# Change to (for example, to use Google's DNS servers):
DEFAULT_OPTS="--log-queries --log-facility=- --no-hosts --server=8.8.8.8 --server=1.1.1.1"

Rebuild the Docker image:

docker build -t my-custom-dns .

Run the container as before. Now it will resolve your custom A records and forward other queries to the specified upstream servers (e.g., 8.8.8.8 and 1.1.1.1).

Additional dnsmasq Options

You can pass additional command-line options to dnsmasq when you run the Docker container. These options will be appended to the ones configured by the entrypoint.sh script.

Example: To set a custom DNS cache size:

docker run -d --name dns-server \
  -p 53:53/udp \
  -p 53:53/tcp \
  -e A_RECORD_WEB="myapp.local=192.168.1.10" \
  my-custom-dns --cache-size=1000

Here, --cache-size=1000 is passed as an additional argument to dnsmasq.

Viewing Logs
DNS query logs are sent to stderr by dnsmasq. You can view them using:

docker logs dns-server

(Replace dns-server with your container's name if different.)

Troubleshooting
"WARN: Malformed or incomplete A_RECORD variable...": Check the format of your A_RECORD_ environment variables. They must be HOSTNAME=IP_ADDRESS.

"WARN: No A_RECORD_ environment variables found..."*: Ensure your environment variables are correctly prefixed with A_RECORD_ and are being passed to the container.

Connection refused/timeout when querying:

Verify the container is running (docker ps).

Check that ports 53/udp and 53/tcp are correctly mapped (docker port dns-server).

Ensure your firewall is not blocking traffic to port 53 on the Docker host.

Check docker logs dns-server for any error messages from dnsmasq.