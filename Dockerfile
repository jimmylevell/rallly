FROM node:alpine

RUN apk update && apk add --no-cache dos2unix

RUN mkdir -p /usr/src/app
RUN mkdir -p /docker
ENV PORT 3000

WORKDIR /usr/src/app

COPY ./docker/entrypoint.sh /docker/entrypoint.sh
RUN chmod +x /docker/entrypoint.sh
RUN dos2unix /docker/entrypoint.sh

COPY package.json /usr/src/app
COPY yarn.lock /usr/src/app
COPY prisma/schema.prisma /usr/src/app

RUN yarn --frozen-lockfile

COPY . /usr/src/app

RUN --mount=type=secret,id=NEXT_PUBLIC_BASE_URL \
  --mount=type=secret,id=DATABASE_URL_RALLY \
   export NEXT_PUBLIC_BASE_URL=$(cat /run/secrets/NEXT_PUBLIC_BASE_URL) && \
   export DATABASE_URL=$(cat /run/secrets/DATABASE_URL_RALLY) && \
   yarn build

EXPOSE 3000

ENTRYPOINT [ "/docker/entrypoint.sh" ]