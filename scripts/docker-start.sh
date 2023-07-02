#!/bin/bash

# call docker secret expansion in env variables
source /docker/set_env_secrets.sh

set -e
prisma migrate deploy --schema=./prisma/schema.prisma
node apps/web/server.js
