#!/bin/sh
# Render docker-compose.portainer.yml with a prod-like env and assert the values the
# production stack depends on. Catches lost env passthroughs and silent default
# drift before they reach a redeploy.
set -eu
cd "$(dirname "$0")/../.."
ENVF=deploy/wb-compat/stack-config-test.env

OUT=$(docker compose --env-file "$ENVF" -f docker-compose.portainer.yml config)

fail=0
need() {
  if ! printf '%s\n' "$OUT" | grep -Eq "$1"; then
    echo "FAIL: expected /$1/ in rendered config" >&2
    fail=1
  fi
}

# image identity: the host must pull the CI-published image, never build or reuse a
# local tag - a stale local image is how a deploy silently ran old code before
need 'image: ghcr.io/wb-aleksandr-khlebnikov/tg-spam:master'
need 'pull_policy: always'

# values the stack env pins
need 'OPENAI_MODEL: gpt-5.6-sol'
need 'MIN_PROBABILITY: "?35"?'
need 'META_LINKS_LIMIT: "?1"?'
need 'META_MENTIONS_LIMIT: "?1"?'
need 'META_GIVEAWAY: "?true"?'
need 'META_CONTACT_ONLY: "?true"?'
# values that must come from file defaults (stack env does not set them)
need 'MIN_MSG_LEN: "?40"?'
need 'SIMILARITY_THRESHOLD: "?0.65"?'
need 'FIRST_MESSAGES_COUNT: "?5"?'
need 'HISTORY_DURATION: "?72h"?'
need 'DELETE_JOIN_MESSAGES: "?true"?'
need 'DELETE_LEAVE_MESSAGES: "?true"?'
# volume identity
need 'name: tg-spam-wirenboard-chat_tg-spam-wb_data'
need 'name: tg-spam-wirenboard-chat_tg-spam-wb_log'

# a stack must not render at all without explicit volume names
if docker compose -f docker-compose.portainer.yml config >/dev/null 2>&1; then
  echo "FAIL: config rendered without DATA_VOLUME_NAME/LOG_VOLUME_NAME - :? guard lost" >&2
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "stack config OK"
fi
exit "$fail"
