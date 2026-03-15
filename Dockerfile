# syntax=docker/dockerfile:1

FROM dhi.io/eclipse-mosquitto:2

# you must have use openssl to establish a secure connection.
# hardened image already have openssl installed.

WORKDIR /ac
 
COPY run.sh run.sh

ENTRYPOINT ["sh", "run.sh"]