#!/bin/bash

# call docker secret expansion in env variables
source /app/set_env_secrets.sh

set -e
prisma migrate deploy --schema=./prisma/schema.prisma
NEXTAUTH_URL=$NEXT_PUBLIC_BASE_URL node apps/web/server.js
