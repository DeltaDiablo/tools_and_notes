#!/bin/bash
# Check and fix all file bind mounts in Malcolm - create files if missing
BASE=/mnt/d/development/GitKraken/tools_and_notes/development/Malcolm_project

# Files that must exist as files (not directories) 
FILE_MOUNTS=(
  ".opensearch.primary.curlrc"
  ".opensearch.secondary.curlrc"
  "arkime/etc/wise.ini"
  "filebeat/certs/ca.crt"
  "filebeat/certs/client.crt"
  "filebeat/certs/client.key"
  "logstash/certs/ca.crt"
  "logstash/certs/server.crt"
  "logstash/certs/server.key"
  "logstash/maps/malcolm_severity.yaml"
  "nginx/certs/dhparam.pem"
  "nginx/htpasswd"
  "nginx/nginx_ldap.conf"
  "opensearch/opensearch.keystore"
  "htadmin/metadata"
)

# Directories that must exist
DIR_MOUNTS=(
  "arkime/lua"
  "arkime/rules"
  "filescan-logs"
  "netbox/config"
  "netbox/custom-plugins"
  "netbox/media"
  "netbox/preload"
  "nginx/ca-trust"
  "nginx/certs"
  "opensearch"
  "opensearch-backup"
  "pcap"
  "pcap/upload"
  "postgres"
  "redis"
  "strelka/config/backend"
  "strelka/config/frontend"
  "strelka/config/manager"
  "suricata-logs"
  "suricata/include-configs"
  "suricata/rules"
  "yara/rules"
  "zeek-logs"
  "zeek-logs/extract_files"
  "zeek-logs/extract_files/filescan"
  "zeek-logs/live"
  "zeek-logs/upload"
  "zeek/custom"
  "zeek/intel"
)

echo "=== Checking directory mounts ==="
for d in "${DIR_MOUNTS[@]}"; do
  path="$BASE/$d"
  if [ -f "$path" ]; then
    echo "FIXING: $d is a file, converting to directory"
    rm -f "$path"
    mkdir -p "$path"
  elif [ ! -d "$path" ]; then
    mkdir -p "$path"
    echo "Created directory: $d"
  fi
done

echo ""
echo "=== Checking file mounts ==="
for f in "${FILE_MOUNTS[@]}"; do
  path="$BASE/$f"
  # Ensure parent directory exists
  mkdir -p "$(dirname "$path")"
  
  if [ -d "$path" ]; then
    echo "FIXING: $f is a directory, converting to file"
    rm -rf "$path"
    touch "$path"
    echo "  Fixed: $f"
  elif [ ! -f "$path" ]; then
    touch "$path"
    echo "Created: $f"
  fi
done

echo ""
echo "=== Done ==="
ls -la "$BASE/opensearch/opensearch.keystore"
ls -la "$BASE/.opensearch.primary.curlrc"
