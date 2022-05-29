FROM node:alpine

RUN --mount=type=secret,id=NEXT_PUBLIC_BASE_URL \
   export NEXT_PUBLIC_BASE_URL=$(cat /run/secrets/NEXT_PUBLIC_BASE_URL)

RUN mkdir -p /usr/src/app
ENV PORT 3000
ARG DATABASE_URL
ENV DATABASE_URL $DATABASE_URL

WORKDIR /usr/src/app

COPY package.json /usr/src/app
COPY yarn.lock /usr/src/app
COPY prisma/schema.prisma /usr/src/app

RUN yarn --frozen-lockfile

COPY . /usr/src/app

ARG NEXT_PUBLIC_BASE_URL
ENV NEXT_PUBLIC_BASE_URL $NEXT_PUBLIC_BASE_URL

RUN yarn build

EXPOSE 3000

ENTRYPOINT [ "/docker/entrypoint.sh" ]