# syntax=docker/dockerfile:1

FROM eclipse-mosquitto:2.1-alpine

RUN apk update \
    && apk upgrade \
    && apk add --no-cache \
    openssl

WORKDIR /ac
 
COPY run.sh run.sh

ENTRYPOINT ["sh", "run.sh"]