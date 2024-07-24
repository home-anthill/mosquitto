#!/bin/sh
set -e

mkdir -p /etc/mosquitto
mkdir -p /etc/mosquitto/certs

ps -a

if [ ${MOSQUITTO_USERNAME+x} ] && [ ${MOSQUITTO_PASSWORD+x} ]; then
  echo "Configuring authentication"
  # set user and password for mosquitto
  mosquitto_passwd -b -c ./password_file ${MOSQUITTO_USERNAME} ${MOSQUITTO_PASSWORD}
  ls -la ./
  cp ./password_file /etc/mosquitto/password_file
  chown mosquitto:mosquitto /etc/mosquitto/password_file
  chmod 0600 /etc/mosquitto/password_file
else
  echo "Skipping authentication"
fi

ls -la /etc/mosquitto/certs

sleep 10
# start mosquitto
mosquitto -c /mosquitto/config/mosquitto.conf

sleep infinity