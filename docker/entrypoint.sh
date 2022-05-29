#!/bin/sh

# call docker secret expansion in env variables
source /docker/set_env_secrets.sh

sh -c "yarn prisma migrate deploy --schema prisma/schema.prisma && yarn start"

yarn start