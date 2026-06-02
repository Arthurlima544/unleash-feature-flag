#!/usr/bin/env bash
# Initializes Unleash feature flags via Admin REST API.
# Run after `docker compose up unleash` is healthy:
#   ./scripts/unleash-init.sh

set -euo pipefail

UNLEASH_URL="${UNLEASH_URL:-http://localhost:4242}"
ADMIN_TOKEN="${ADMIN_TOKEN:-*:*.unleash-admin-token}"
PROJECT="default"
ENV="development"

# ── helpers ──────────────────────────────────────────────────────────────────

wait_for_unleash() {
  echo "Waiting for Unleash at $UNLEASH_URL ..."
  for i in $(seq 1 30); do
    if curl -sf "$UNLEASH_URL/health" > /dev/null 2>&1; then
      echo "Unleash is ready."
      return 0
    fi
    sleep 2
  done
  echo "ERROR: Unleash did not become healthy in time." >&2
  exit 1
}

create_flag() {
  local name="$1" type="$2" description="$3"
  echo "  Creating $name ..."
  curl -sf -X POST "$UNLEASH_URL/api/admin/projects/$PROJECT/features" \
    -H "Authorization: $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"$name\",\"type\":\"$type\",\"description\":\"$description\"}" \
    > /dev/null || echo "    (already exists, skipping)"
}

add_default_strategy() {
  local name="$1"
  curl -sf -X POST "$UNLEASH_URL/api/admin/projects/$PROJECT/features/$name/environments/$ENV/strategies" \
    -H "Authorization: $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"name":"default","parameters":{},"constraints":[],"segments":[]}' \
    > /dev/null
}

enable_flag() {
  local name="$1"
  curl -sf -X POST "$UNLEASH_URL/api/admin/projects/$PROJECT/features/$name/environments/$ENV/on" \
    -H "Authorization: $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    > /dev/null
}

setup_flag() {
  local name="$1" type="$2" description="$3" enabled="$4"
  create_flag "$name" "$type" "$description"
  add_default_strategy "$name"
  if [ "$enabled" = "true" ]; then
    enable_flag "$name"
    echo "    ✓ $name → ENABLED"
  else
    echo "    ○ $name → DISABLED"
  fi
}

# ── run ───────────────────────────────────────────────────────────────────────

wait_for_unleash

echo ""
echo "Creating feature flags in project '$PROJECT', environment '$ENV':"
echo ""

#        NAME                           TYPE       DESCRIPTION                                  ENABLED
setup_flag GENERAL_DARK_MODE            release   "Dark mode theme across all platforms"        true
setup_flag GENERAL_NOTIFICATION_CENTER  release   "Notification bell and panel for all clients" false
setup_flag BACKEND_ADVANCED_SEARCH      release   "Advanced search endpoint with facets"        true
setup_flag BACKEND_AI_RECOMMENDATIONS   experiment "AI-powered product recommendations"         false
setup_flag WEB_NEW_DASHBOARD            release   "Redesigned dashboard layout in Angular"      true
setup_flag WEB_EXPERIMENTAL_CHARTS      experiment "Experimental chart components in Angular"   false
setup_flag MOBILE_BIOMETRIC_AUTH        release   "Biometric authentication UI in Flutter"      true
setup_flag MOBILE_OFFLINE_MODE          release   "Offline mode banner and sync in Flutter"     false

echo ""
echo "Done. Open http://localhost:4242 (admin / unleash4all) to manage flags in the UI."
