# syntax=docker/dockerfile:1

FROM eclipse-mosquitto:2.0-openssl

RUN apk update \
    && apk upgrade \
    && apk add --no-cache \
    openssl

WORKDIR /ac
 
COPY run.sh run.sh

COPY mosquitto.conf /mosquitto/config/mosquitto.conf
COPY mosquitto-nossl.conf /mosquitto/config/mosquitto-nossl.conf
COPY mosquitto-auth.conf /mosquitto/config/mosquitto-auth.conf
COPY mosquitto-nossl-auth.conf /mosquitto/config/mosquitto-nossl-auth.conf

ENTRYPOINT ["sh", "run.sh"]