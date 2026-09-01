#!/usr/bin/env bash
# One-time local setup: verify sibling repos are present, seed missing .env files,
# then hand off to `docker compose up`.
set -euo pipefail

INFRA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PARENT_DIR="$(dirname "$INFRA_DIR")"

BACKEND_DIR="$PARENT_DIR/vegan-backend"
ADMIN_DIR="$PARENT_DIR/vegan-Admin"
FRONTEND_DIR="$PARENT_DIR/VeganFit_Next-Frontend"

for repo in "$BACKEND_DIR" "$ADMIN_DIR" "$FRONTEND_DIR"; do
  if [ ! -d "$repo" ]; then
    echo "Missing sibling repo: $repo" >&2
    echo "This infra repo expects to sit next to vegan-backend, vegan-Admin and VeganFit_Next-Frontend" \
         "in the same parent folder (that's already how they're laid out under vegan/)." >&2
    exit 1
  fi
done

if [ ! -f "$BACKEND_DIR/.env" ]; then
  echo "Seeding $BACKEND_DIR/.env from .env.example"
  cp "$BACKEND_DIR/.env.example" "$BACKEND_DIR/.env"
fi

if [ ! -f "$ADMIN_DIR/.env" ]; then
  echo "Seeding $ADMIN_DIR/.env from .env.example"
  cp "$ADMIN_DIR/.env.example" "$ADMIN_DIR/.env"
fi

if [ ! -f "$FRONTEND_DIR/.env.local" ]; then
  echo "Seeding $FRONTEND_DIR/.env.local with local defaults"
  cat > "$FRONTEND_DIR/.env.local" <<'EOF'
NEXT_PUBLIC_BACKEND_URL=http://localhost:4000
NEXT_PUBLIC_APP_URL=http://localhost:3000
EOF
fi

if [ ! -f "$INFRA_DIR/.env" ]; then
  cp "$INFRA_DIR/.env.example" "$INFRA_DIR/.env"
fi

cd "$INFRA_DIR"
docker compose up --build
