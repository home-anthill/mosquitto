# syntax=docker/dockerfile:1

FROM eclipse-mosquitto:2.0-openssl

RUN apk update \
    && apk upgrade \
    && apk add --no-cache \
    openssl

WORKDIR /ac
 
COPY run.sh run.sh

ENTRYPOINT ["sh", "run.sh"]