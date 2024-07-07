#!/bin/sh
set -e

if [ ${MOSQUITTO_SSL_ENABLE+x} ]; then
  echo "SSL enabled"
  CERT_DIR=/etc/mosquitto/certs
  mkdir -p ${CERT_DIR}

  echo "Copying SSL certs"
  cp "/tls/tls.crt" ${CERT_DIR}/cert.pem
  cp "/tls/ca.crt" ${CERT_DIR}/chain.pem
  cp "/tls/tls.key" ${CERT_DIR}/privkey.pem

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
    mosquitto_passwd -b -c /etc/mosquitto/password_file ${MOSQUITTO_USERNAME} ${MOSQUITTO_PASSWORD}
    chown mosquitto:mosquitto /etc/mosquitto/password_file
    chmod 0600 /etc/mosquitto/password_file
    # start mosquitto with user/password authentication
    mosquitto -c /mosquitto/config/mosquitto-auth.conf
  else
    echo "Skipping authentication with SSL"
    # start mosquitto without authentication
    mosquitto -c /mosquitto/config/mosquitto.conf
  fi
else
  echo "SSL NOT enabled"
  ps -a

  if [ ${MOSQUITTO_USERNAME+x} ] && [ ${MOSQUITTO_PASSWORD+x} ]; then
    echo "Configuring authentication without SSL"
    echo "mosquitto username ${MOSQUITTO_USERNAME}"
    echo "mosquitto password ${MOSQUITTO_PASSWORD}"
    # set user and password for mosquitto
    mosquitto_passwd -b -c /etc/mosquitto/password_file ${MOSQUITTO_USERNAME} ${MOSQUITTO_PASSWORD}
    chown mosquitto:mosquitto /etc/mosquitto/password_file
    chmod 0600 /etc/mosquitto/password_file
    # start mosquitto with user/password authentication
    mosquitto -c /mosquitto/config/mosquitto-nossl-auth.conf
  else
    echo "Skipping authentication without SSL"
    # start mosquitto without authentication
    mosquitto -c /mosquitto/config/mosquitto-nossl.conf
  fi
fi

sleep infinity