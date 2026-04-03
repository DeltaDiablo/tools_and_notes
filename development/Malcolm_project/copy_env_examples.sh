#!/bin/bash
# Copy all .env.example files to .env (skip config files that already exist)
BASE=/mnt/d/development/GitKraken/tools_and_notes/development/Malcolm_project

cd "$BASE/config"
for f in *.env.example; do
  target="${f%.example}"
  if [ ! -f "$target" ]; then
    cp "$f" "$target"
    echo "Created $target"
  else
    echo "Skipped $target (already exists)"
  fi
done

echo ""
echo "Config files present:"
ls *.env 2>/dev/null
