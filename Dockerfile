FROM node:16 AS builder

WORKDIR /app
RUN yarn global add turbo
COPY . .
RUN turbo prune --scope=@rallly/web --docker

FROM node:16 AS installer

WORKDIR /app
COPY .gitignore .gitignore
COPY --from=builder /app/out/json/ .
COPY --from=builder /app/out/yarn.lock ./yarn.lock
RUN yarn --network-timeout 1000000

# Build the project
COPY --from=builder /app/out/full/ .
COPY turbo.json turbo.json
RUN yarn db:generate

ARG APP_VERSION
ENV NEXT_PUBLIC_APP_VERSION=$APP_VERSION

RUN --mount=type=secret,id=NEXT_PUBLIC_BASE_URL \
  --mount=type=secret,id=DATABASE_URL_RALLY \
  export NEXT_PUBLIC_BASE_URL=$(cat /run/secrets/NEXT_PUBLIC_BASE_URL) && \
  export DATABASE_URL=$(cat /run/secrets/DATABASE_URL_RALLY) && \
  yarn build

FROM node:16 AS runner

WORKDIR /app

RUN apt-get update && apt-get install -y dos2unix
RUN yarn global add prisma
# Don't run production as root
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY ./docker/entrypoint.sh /docker/entrypoint.sh
RUN chmod +x /docker/entrypoint.sh
RUN dos2unix /docker/entrypoint.sh

COPY ./docker/set_env_secrets.sh /docker/set_env_secrets.sh
RUN chmod +x /docker/set_env_secrets.sh
RUN dos2unix /docker/set_env_secrets.sh

COPY ./scripts/docker-start.sh /app/scripts/docker-start.sh
RUN chmod +x /app/scripts/docker-start.sh
RUN dos2unix /app/scripts/docker-start.sh

USER nextjs

COPY --from=builder --chown=nextjs:nodejs /app/packages/database/prisma ./prisma
COPY --from=installer /app/apps/web/next.config.js .
COPY --from=installer /app/apps/web/package.json .

ENV PORT 3000
EXPOSE 3000

# Automatically leverage output traces to reduce image size
# https://nextjs.org/docs/advanced-features/output-file-tracing
COPY --from=installer --chown=nextjs:nodejs /app/apps/web/.next/standalone ./
COPY --from=installer --chown=nextjs:nodejs /app/apps/web/.next/static ./apps/web/.next/static
COPY --from=installer --chown=nextjs:nodejs /app/apps/web/public ./apps/web/public

CMD ["./docker-start.sh"]
