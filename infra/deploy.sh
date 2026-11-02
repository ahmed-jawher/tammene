#!/usr/bin/env bash
# Runs on the server (called by .github/workflows/deploy.yml over SSH, or by hand):
#   bash infra/deploy.sh <commit-sha>
# Pulls that commit's images, takes a backup, starts them and waits for the API to be healthy.
# If the new API never becomes healthy, the previous images are started again and the script
# fails. Database migrations are NOT undone (they may delete data) — see docs/DEPLOY.md §6.
set -euo pipefail

TAG="${1:?usage: deploy.sh <commit-sha>}"
cd "$(dirname "$0")/.."

compose() {
  docker compose -f infra/docker-compose.prod.yml -f infra/docker-compose.images.yml \
    --env-file .env.production --env-file .deploy.env "$@"
}
# The image name is kept beside the tag: images built before the repository was renamed
# (busstuid → tammene) carry the old name, and a rollback must start those, not look for them
# under the new one. The exported value wins over .deploy.env inside compose.
use_version() {
  printf 'IMAGE_PREFIX=%s\nIMAGE_TAG=%s\n' "$1" "$2" > .deploy.env
  export IMAGE_PREFIX="$1"
}
wait_healthy() {
  for _ in $(seq 1 36); do
    [ "$(docker inspect -f '{{.State.Health.Status}}' "$(compose ps -q api)" 2>/dev/null)" = healthy ] && return 0
    sleep 5
  done
  return 1
}

PREFIX="${IMAGE_PREFIX:-ghcr.io/ahmed-jawher/tammene}"
PREVIOUS="$(sed -n 's/^IMAGE_TAG=//p' .deploy.env 2>/dev/null || true)"
PREVIOUS_PREFIX="$(sed -n 's/^IMAGE_PREFIX=//p' .deploy.env 2>/dev/null || true)"
PREVIOUS_PREFIX="${PREVIOUS_PREFIX:-ghcr.io/ahmed-jawher/busstuid}"

echo "→ pulling images for ${TAG}"
use_version "$PREFIX" "$TAG"
compose pull --quiet api web backup

# Backup of the current database before migrations run. Skipped only on a first install.
if [ -n "$(compose ps -q backup 2>/dev/null)" ]; then
  echo "→ backup before deploy"
  compose exec -T backup node dist/ops/cli.js backup
fi

echo "→ starting ${TAG}"
compose up -d --no-build --remove-orphans
if wait_healthy; then
  docker image prune -af --filter "until=168h" > /dev/null
  echo "✓ ${TAG} is live"
  exit 0
fi

echo "✗ API not healthy on ${TAG}" >&2
compose logs --tail 80 api >&2 || true
if [ -n "$PREVIOUS" ] && [ "$PREVIOUS_PREFIX:$PREVIOUS" != "$PREFIX:$TAG" ]; then
  echo "→ starting the previous version ${PREVIOUS} again" >&2
  use_version "$PREVIOUS_PREFIX" "$PREVIOUS"
  compose up -d --no-build --remove-orphans
  wait_healthy && echo "✓ back on ${PREVIOUS}" >&2
fi
exit 1
