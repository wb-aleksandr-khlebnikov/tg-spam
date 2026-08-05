#!/bin/sh
# Build the locally-tagged image the portainer stack runs. The stack uses
# pull_policy: never, so this must be run on the docker host (from a checkout of
# the ref you want to deploy) before switching or redeploying the stack.
set -eu
cd "$(dirname "$0")/../.."
docker build -t tg-spam-wb-compat:latest .
echo "built tg-spam-wb-compat:latest"
