#!/bin/bash
set -e
BASE=/mnt/d/development/GitKraken/tools_and_notes/development/Malcolm_project

# Generate bcrypt password hash for admin:testbuilDer
ADMIN_HTPASSWD_HASH=$(htpasswd -n -B -b admin testbuilDer 2>/dev/null | cut -d: -f2)
echo "Generated htpasswd hash for admin"

# Run auth_setup noninteractively
cd "$BASE"
set +e
python3 "$BASE/malcolm_scripts/auth_setup" \
  --file "$BASE/docker-compose.yml" \
  --environment-dir "$BASE/config" \
  --auth-noninteractive \
  --auth-method basic \
  --auth-admin-username admin \
  --auth-admin-password-htpasswd "$ADMIN_HTPASSWD_HASH" \
  --auth-arkime-password "testbuilDer" \
  --auth-generate-webcerts
RC=$?
echo "auth_setup exit code: $RC"
echo ""
echo "Checking generated files:"
ls -la "$BASE/.opensearch.primary.curlrc" 2>/dev/null || echo "curlrc NOT created"
ls -la "$BASE/nginx/htpasswd" 2>/dev/null || echo "nginx/htpasswd NOT created"
ls -la "$BASE/nginx/certs/" 2>/dev/null || echo "nginx/certs NOT created"
