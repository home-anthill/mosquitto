#!/bin/sh
set -e

if [ ${CERTBOT_EMAIL+x} ] && [ ${CERTBOT_DOMAIN+x} ] && [ ${CERTBOT_SERVER+x} ]; then
  # Let's encrypt certificates
  #Certificate is saved at: /etc/letsencrypt/live/<DOMAIN>/fullchain.pem
  #Key is saved at:         /etc/letsencrypt/live/<DOMAIN>/privkey.pem

  echo "Printing 'crontab'"
  crontab -l
  echo "Run crond as background process"
  crond -b -l 0 -L /ac/crond.log
  
  # read env variables
  echo "Env variables:"
  echo "CERTBOT_EMAIL = ${CERTBOT_EMAIL}"
  echo "CERTBOT_DOMAIN = ${CERTBOT_DOMAIN}"
  echo "CERTBOT_SERVER = ${CERTBOT_SERVER}"
  echo "MOSQUITTO_USERNAME = ${MOSQUITTO_USERNAME}"
  echo "MOSQUITTO_PASSWORD = ${MOSQUITTO_PASSWORD}"

  if [ -d "/etc/letsencrypt/live/${CERTBOT_DOMAIN}" ]
  then
    echo "Certificates already exists"
  else
    echo "Requesting certificates using certbot via production server"
    certbot certonly --standalone -m "${CERTBOT_EMAIL}" --agree-tos -d ${CERTBOT_DOMAIN},www.${CERTBOT_DOMAIN} -n --server "${CERTBOT_SERVER}"
    # staging server:
    # certbot certonly --standalone -m "${CERTBOT_EMAIL" --agree-tos -d ${certbot_domain},www.${certbot_domain} -n --server https://acme-staging-v02.api.letsencrypt.org/directory
  fi

  CERT_DIR=/etc/mosquitto/certs
  mkdir -p ${CERT_DIR}

  cp "/etc/letsencrypt/live/${CERTBOT_DOMAIN}/cert.pem" ${CERT_DIR}/cert.pem
  cp "/etc/letsencrypt/live/${CERTBOT_DOMAIN}/chain.pem" ${CERT_DIR}/chain.pem
  cp "/etc/letsencrypt/live/${CERTBOT_DOMAIN}/fullchain.pem" ${CERT_DIR}/fullchain.pem
  cp "/etc/letsencrypt/live/${CERTBOT_DOMAIN}/privkey.pem" ${CERT_DIR}/privkey.pem

  # Set ownership to Mosquitto
  chown mosquitto: ${CERT_DIR}/cert.pem ${CERT_DIR}/chain.pem ${CERT_DIR}/fullchain.pem ${CERT_DIR}/privkey.pem

  # Ensure permissions are restrictive
  chmod 0600 ${CERT_DIR}/cert.pem ${CERT_DIR}/chain.pem ${CERT_DIR}/fullchain.pem ${CERT_DIR}/privkey.pem

  ls -la ${CERT_DIR}
  ps -a

  if [ ${MOSQUITTO_USERNAME+x} ] && [ ${MOSQUITTO_PASSWORD+x} ]; then
    # set user and password for mosquitto
    mosquitto_passwd -b -c /etc/mosquitto/password_file ${MOSQUITTO_USERNAME} ${MOSQUITTO_PASSWORD}
    # start mosquitto with user/password authentication
    mosquitto -c /mosquitto/config/mosquitto-auth.conf
  else
    # start mosquitto without authentication
    mosquitto -c /mosquitto/config/mosquitto.conf
  fi
else
  ps -a

  if [ ${MOSQUITTO_USERNAME+x} ] && [ ${MOSQUITTO_PASSWORD+x} ]; then
    # set user and password for mosquitto
    mosquitto_passwd -b -c /etc/mosquitto/password_file ${MOSQUITTO_USERNAME} ${MOSQUITTO_PASSWORD}
    # start mosquitto with user/password authentication
    mosquitto -c /mosquitto/config/mosquitto-nossl-auth.conf
  else
    # start mosquitto without authentication
    mosquitto -c /mosquitto/config/mosquitto-nossl.conf
  fi
fi

sleep infinity