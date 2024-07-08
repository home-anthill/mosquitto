#!/bin/sh
set -e

mkdir -p /etc/mosquitto

if [ ${MOSQUITTO_SSL_ENABLE+x} ]; then
  echo "SSL enabled"
  CERT_DIR=/etc/mosquitto/certs
  mkdir -p ${CERT_DIR}

  echo "Copying SSL certs"
  cp "/tls/tls.crt" ${CERT_DIR}/cert.pem
  cp "/tls/tls.key" ${CERT_DIR}/privkey.pem

  # if you are using the production let's encrypt server you should use 'ca-certificates.crt'
  # otherwise in case of staging server, you should use 'tls.crt' also as 'chain.pem'
  # cp "/tls/tls.key" ${CERT_DIR}/chain.pem
  cp "/etc/ssl/certs/ca-certificates.crt" ${CERT_DIR}/chain.pem

  # Set ownership to Mosquitto
  chown mosquitto: ${CERT_DIR}/cert.pem ${CERT_DIR}/chain.pem ${CERT_DIR}/privkey.pem

  # Ensure permissions are restrictive
  chmod 0600 ${CERT_DIR}/cert.pem ${CERT_DIR}/chain.pem ${CERT_DIR}/privkey.pem

  ls -la ${CERT_DIR}
  ps -a

  if [ ${MOSQUITTO_USERNAME+x} ] && [ ${MOSQUITTO_PASSWORD+x} ]; then
    echo "Configuring authentication with SSL"
    echo "mosquitto username ${MOSQUITTO_USERNAME}"
    echo "mosquitto password ${MOSQUITTO_PASSWORD}"
    # set user and password for mosquitto
    mosquitto_passwd -b -c ./password_file ${MOSQUITTO_USERNAME} ${MOSQUITTO_PASSWORD}
    ls -la ./
    cp ./password_file /etc/mosquitto/password_file
    chown mosquitto:mosquitto /etc/mosquitto/password_file
    chmod 0600 /etc/mosquitto/password_file
  else
    echo "Skipping authentication with SSL"
  fi
else
  echo "SSL NOT enabled"
  ps -a

  if [ ${MOSQUITTO_USERNAME+x} ] && [ ${MOSQUITTO_PASSWORD+x} ]; then
    echo "Configuring authentication without SSL"
    echo "mosquitto username ${MOSQUITTO_USERNAME}"
    echo "mosquitto password ${MOSQUITTO_PASSWORD}"
    # set user and password for mosquitto
    mosquitto_passwd -b -c ./password_file ${MOSQUITTO_USERNAME} ${MOSQUITTO_PASSWORD}
    ls -la ./
    cp ./password_file /etc/mosquitto/password_file
    chown mosquitto:mosquitto /etc/mosquitto/password_file
    chmod 0600 /etc/mosquitto/password_file
  else
    echo "Skipping authentication without SSL"
  fi
fi

# start mosquitto without authentication
mosquitto -c /mosquitto/config/mosquitto.conf

sleep infinity