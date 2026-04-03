#!/bin/bash
# Generate all Malcolm authentication files manually (replaces auth_setup)
BASE=/mnt/d/development/GitKraken/tools_and_notes/development/Malcolm_project

MALCOLM_ADMIN_USER="admin"
MALCOLM_ADMIN_PASS="testbuilDer"
INTERNAL_USER="malcolm_internal"

# Generate a 36-character random password for the internal service account
# (same logic as auth_setup's localos section)
INTERNAL_PASS=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9_' | fold -w 36 | head -n 1)
echo "Internal service account password generated"

# 1. Write .opensearch.primary.curlrc
# Format: user: "username:password" followed by insecure
cat > "$BASE/.opensearch.primary.curlrc" << CURLEOF
user: "${INTERNAL_USER}:${INTERNAL_PASS}"
insecure
CURLEOF
chmod 600 "$BASE/.opensearch.primary.curlrc"
echo "Created .opensearch.primary.curlrc (user: $INTERNAL_USER)"

# 2. Write .opensearch.secondary.curlrc (empty for local setup)
touch "$BASE/.opensearch.secondary.curlrc"
chmod 600 "$BASE/.opensearch.secondary.curlrc"
echo "Created .opensearch.secondary.curlrc (empty)"

# 3. Create nginx/htpasswd with bcrypt hash for the admin user
mkdir -p "$BASE/nginx"
htpasswd -n -B -b "$MALCOLM_ADMIN_USER" "$MALCOLM_ADMIN_PASS" > "$BASE/nginx/htpasswd"
echo "Created nginx/htpasswd for user: $MALCOLM_ADMIN_USER"

# 4. Create nginx/ca-trust directory (needed as bind mount)
mkdir -p "$BASE/nginx/ca-trust"
echo "Created nginx/ca-trust/"

# 5. Generate self-signed TLS certificate for nginx
mkdir -p "$BASE/nginx/certs"
openssl req -x509 -newkey rsa:2048 \
  -keyout "$BASE/nginx/certs/key.pem" \
  -out "$BASE/nginx/certs/cert.pem" \
  -days 3650 -nodes \
  -subj "/CN=malcolm/OU=Malcolm/O=Malcolm/ST=ID/C=US" \
  2>/dev/null
echo "Generated nginx TLS certificate"

# 6. Generate DH params (use 2048-bit for reasonable speed)
openssl dhparam -out "$BASE/nginx/certs/dhparam.pem" 2048 2>/dev/null
echo "Generated DH params"

# 7. Update config/auth.env with the admin credentials
# MALCOLM_PASSWORD needs to be base64-encoded bcrypt hash
HTPASSWD_HASH=$(htpasswd -n -B -b "$MALCOLM_ADMIN_USER" "$MALCOLM_ADMIN_PASS" | cut -d: -f2)
# Encode the hash as base64
MALCOLM_PASSWORD_B64=$(echo -n "$HTPASSWD_HASH" | base64 | tr -d '\n')
# Update auth.env
sed -i "s|^MALCOLM_USERNAME=.*|MALCOLM_USERNAME=$MALCOLM_ADMIN_USER|" "$BASE/config/auth.env"
sed -i "s|^MALCOLM_PASSWORD=.*|MALCOLM_PASSWORD=${MALCOLM_PASSWORD_B64}|" "$BASE/config/auth.env"
echo "Updated config/auth.env"

# 8. Update config/auth-common.env
sed -i "s|^NGINX_AUTH_MODE=.*|NGINX_AUTH_MODE=basic|" "$BASE/config/auth-common.env"
echo "Updated config/auth-common.env NGINX_AUTH_MODE=basic"

echo ""
echo "=== Auth files created successfully ==="
echo "Malcolm admin: admin / testbuilDer"
echo "Internal OS user: $INTERNAL_USER"
ls -la "$BASE/.opensearch.primary.curlrc" "$BASE/nginx/htpasswd" "$BASE/nginx/certs/cert.pem"
