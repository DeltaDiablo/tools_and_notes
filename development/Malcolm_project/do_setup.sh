#!/bin/bash
BASE=/mnt/d/development/GitKraken/tools_and_notes/development/Malcolm_project
SRC=$BASE/malcolm_20260219_203741_a5c6c91c

# Backup user's .env
cp "$BASE/.env" /tmp/user_env_backup.txt
echo "Backed up .env"

# Copy official docker-compose.yml
cp "$SRC/docker-compose.yml" "$BASE/docker-compose.yml"
echo "Copied docker-compose.yml ($(wc -l < "$BASE/docker-compose.yml") lines)"

# Copy config directory (all .env.example files)
cp -r "$SRC/config" "$BASE/"
echo "Copied config/ ($(ls "$BASE/config/" | wc -l) files)"

# Copy scripts
mkdir -p "$BASE/malcolm_scripts"
cp -r "$SRC/scripts/." "$BASE/malcolm_scripts/"
echo "Copied scripts"

# Copy malcolm support files referenced by docker-compose
for d in htadmin strelka netbox postgres redis filescan-logs yara; do
  if [ -d "$SRC/$d" ]; then
    cp -r "$SRC/$d" "$BASE/"
    echo "Copied $d/"
  fi
done

# Copy nginx templates (merge)
if [ -d "$SRC/nginx" ]; then
  cp -rn "$SRC/nginx/." "$BASE/nginx/"
  echo "Merged nginx/"
fi

# Copy script support files
for f in .envrc.example .justfile .opensearch.primary.curlrc .opensearch.secondary.curlrc; do
  if [ -f "$SRC/$f" ]; then
    cp "$SRC/$f" "$BASE/$f"
  fi
done

echo "Done. Restoring user credentials..."
# Restore user's .env on top
cp /tmp/user_env_backup.txt "$BASE/.env"
echo "User .env restored"
ls "$BASE/"
