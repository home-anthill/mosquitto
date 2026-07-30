# Build
docker build -t ks89/mosquitto:local .

# Prepare directories
mkdir -p data
mkdir -p log
chmod 0700 mosquitto-local-acl.conf

# Run with role-based auth and ACLs
docker run -it --name mosquitto \
    -p 1883:1883 \
    -p 9001:9001 \
    --rm \
    -v ./mosquitto-local-dev.conf:/mosquitto/config/mosquitto.conf:ro \
    -v ./mosquitto-local-acl.conf:/mosquitto/acl/acl_file:ro \
    -v ./data:/mosquitto/data \
    -v ./log:/mosquitto/log \
    -e MOSQUITTO_USERS='device_pubsub:DevicePassword1!,producer_sub:ProducerPassword1!,alarm_receiver_sub:AlarmReceiverPassword1!,api_devices_pub:ApiDevicesPassword1!' \
    ks89/mosquitto:local

If the logs warn that `/mosquitto/acl/acl_file` is world readable, run `chmod 0700 mosquitto-local-acl.conf` on the host and restart the container.
The broker can still start today, but newer Mosquitto versions may reject loose ACL file permissions.

# Check it's running
docker logs mosquitto

To verify the MQTT connection actually works, install the Mosquitto CLI clients:

brew install mosquitto

Then in two terminals:

# Terminal 1 — producer role subscribes to sensor telemetry
mosquitto_sub -h localhost -p 1883 \
  -u producer_sub -P ProducerPassword1! \
  -t "sensors/+/+"

# Terminal 2 — device role publishes sensor telemetry
mosquitto_pub -h localhost -p 1883 \
  -u device_pubsub -P DevicePassword1! \
  -t "sensors/test-device/temperature" \
  -m '{"value":21.5}'

You should see `{"value":21.5}` appear in Terminal 1.

Quick one-liner smoke test (no second terminal needed):

# Publish to a topic allowed for device_pubsub (exit code 0 = connected and published)
mosquitto_pub -h localhost -p 1883 \
  -u device_pubsub -P DevicePassword1! \
  -t "sensors/test-device/temperature" \
  -m '{"value":21.5}' && echo "OK"

Verify auth is enforced (should fail):

mosquitto_pub -h localhost -p 1883 -t "sensors/test-device/temperature" -m "hello"
# Expected: Connection Refused: not authorised

Verify ACLs are enforced (should fail):

mosquitto_pub -h localhost -p 1883 \
  -u producer_sub -P ProducerPassword1! \
  -t "sensors/test-device/temperature" \
  -m '{"value":21.5}'
# Expected: Not authorized

Verify command topic access:

# Terminal 1 — device role can read commands
mosquitto_sub -h localhost -p 1883 \
  -u device_pubsub -P DevicePassword1! \
  -t "devices/test-device/values"

# Terminal 2 — api-devices role can publish commands
mosquitto_pub -h localhost -p 1883 \
  -u api_devices_pub -P ApiDevicesPassword1! \
  -t "devices/test-device/values" \
  -m '[{"value":22}]'

Cleanup:

docker stop mosquitto && docker rm mosquitto
