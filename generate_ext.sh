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

# Create a temporary file for the output
output_temp=$(mktemp)
trap 'rm -f "$output_temp"' EXIT

# Copy the template to the output file
cp "$template_file" "$output_temp"

# Generate DNS entries
if [ -n "$domains" ]; then
    dns_section=""
    count=1
    echo "$domains" | while read -r domain; do
        echo "DNS.$count = $domain" >> "$output_temp"
        count=$((count + 1))
    done
fi

# Generate IP entries
if [ -n "$ips" ]; then
    ip_section=""
    count=1
    echo "$ips" | while read -r ip; do
        echo "IP.$count = $ip" >> "$output_temp"
        count=$((count + 1))
    done
fi

# Output the final file
cat "$output_temp"
