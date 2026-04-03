#!/bin/bash
BASE=/mnt/d/development/GitKraken/tools_and_notes/development/Malcolm_project

# Generate bcrypt password hash for admin:testbuilDer
ADMIN_HTPASSWD_HASH=$(htpasswd -n -B -b admin testbuilDer 2>/dev/null | cut -d: -f2)
echo "Hash: $ADMIN_HTPASSWD_HASH"

# Run auth_setup with verbose and capture all output
cd "$BASE"
python3 "$BASE/malcolm_scripts/auth_setup" \
  --verbose \
  --file "$BASE/docker-compose.yml" \
  --environment-dir "$BASE/config" \
  --auth-noninteractive \
  --auth-method basic \
  --auth-admin-username admin \
  --auth-admin-password-htpasswd "$ADMIN_HTPASSWD_HASH" \
  --auth-arkime-password "testbuilDer" \
  --auth-generate-webcerts \
  > /mnt/d/development/GitKraken/tools_and_notes/development/Malcolm_project/auth_output.log 2>&1
RC=$?
cat /mnt/d/development/GitKraken/tools_and_notes/development/Malcolm_project/auth_output.log
echo "Exit code: $RC"
