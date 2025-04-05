#!/bin/sh

# Exit on any error
set -e

# Check if template file is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <template_file>" >&2
    exit 1
fi

template_file="$1"

# Check if template file exists
if [ ! -f "$template_file" ]; then
    echo "Error: Template file '$template_file' not found" >&2
    exit 1
fi

temp_file=$(mktemp)
trap 'rm -f "$temp_file"' EXIT

# Get domain names
echo "Enter domain names (one per line, press Ctrl+D when done):" >&2
while read -r line; do
    # Skip empty lines
    [ -z "$line" ] && continue
    echo "$line" >> "$temp_file"
done
domains=$(cat "$temp_file")
> "$temp_file"

# Get IP addresses
echo "Enter IP addresses (one per line, press Ctrl+D when done):" >&2
while read -r line; do
    # Skip empty lines
    [ -z "$line" ] && continue
    # Validate IP address format (basic check)
    if ! echo "$line" | grep -qE '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$'; then
        echo "Error: Invalid IP address format: $line" >&2
        exit 1
    fi
    echo "$line" >> "$temp_file"
done
ips=$(cat "$temp_file")

# Check if at least one domain or IP was provided
if [ -z "$domains" ] && [ -z "$ips" ]; then
    echo "Error: No valid domains or IPs provided" >&2
    exit 1
fi

# Generate DNS entries
if [ -n "$domains" ]; then
    dns_entries=$(echo "$domains" | awk '{print "DNS." NR " = " $0}')
else
    dns_entries=""
fi

# Generate IP entries
if [ -n "$ips" ]; then
    ip_entries=$(echo "$ips" | awk '{print "IP." NR " = " $0}')
else
    ip_entries=""
fi

# Check if template contains the required placeholders
if ! grep -q "DNS_ENTRIES\|IP_ENTRIES" "$template_file"; then
    echo "Error: Template file does not contain required placeholders (DNS_ENTRIES or IP_ENTRIES)" >&2
    exit 1
fi

# Generate the .ext file content to stdout
sed -e "s/DNS_ENTRIES/$dns_entries/" -e "s/IP_ENTRIES/$ip_entries/" "$template_file"
