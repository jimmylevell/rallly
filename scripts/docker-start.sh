#!/bin/bash

# call docker secret expansion in env variables
source /app/set_env_secrets.sh

set -e

# Needed by next-auth to verify the origin of the request
export AUTH_URL=$NEXT_PUBLIC_BASE_URL

if [ "$MAINTENANCE_MODE" = "true" ]; then
  # The database may be unreachable during maintenance
  echo "MAINTENANCE_MODE is enabled - skipping database migration"
else
  npx prisma migrate deploy --config=./prisma.config.ts
fi
# Docker/Swarm sets HOSTNAME to the container id; force listening on all interfaces
export HOSTNAME=0.0.0.0
node apps/web/server.js
