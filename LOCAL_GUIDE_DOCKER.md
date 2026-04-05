# Build
docker build -t ks89/mosquitto .

# Prepare directories
mkdir -p data
mkdir -p log

# Run with auth
docker run -it --name mosquitto \
    -p 1883:1883 \
    -p 9001:9001 \
    --rm \
    -v ./mosquitto-local-dev.conf:/mosquitto/config/mosquitto.conf:ro \
    -v ./data:/mosquitto/data \
    -v ./log:/mosquitto/log \
    -e MOSQUITTO_USERNAME=mosquser \
    -e MOSQUITTO_PASSWORD=Password1! \
    ks89/mosquitto

# Check it's running
docker logs mosquitto

To verify the MQTT connection actually works, install the Mosquitto CLI clients:

brew install mosquitto

Then in two terminals:

# Terminal 1 — subscribe
mosquitto_sub -h localhost -p 1883 -u mosquser -P Password1! -t "test/topic"

# Terminal 2 — publish
mosquitto_pub -h localhost -p 1883 -u mosquser -P Password1! -t "test/topic" -m "hello"

You should see hello appear in Terminal 1.

Quick one-liner smoke test (no second terminal needed):

# Terminal 2 – publish with QoS 1 and verify it succeeds (exit code 0 = connected and published)
mosquitto_pub -h localhost -p 1883 -u mosquser -P Password1! -t "test/topic" -m "hello" && echo "OK"

Verify auth is enforced (should fail):

mosquitto_pub -h localhost -p 1883 -t "test/topic" -m "hello"
# Expected: Connection Refused: not authorised

Cleanup:

docker stop mosquitto && docker rm mosquitto