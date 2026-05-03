# Local Kubernetes Mosquitto

Run these commands from the `mosquitto/` directory.

## Start

```bash
kind create cluster --name kind-cluster --image kindest/node:v1.35.0
docker build -t ks89/mosquitto:local .
docker save ks89/mosquitto:local -o mosquitto.tar
kind load image-archive mosquitto.tar --name kind-cluster
rm mosquitto.tar
```

```bash
kubectl create namespace mosquitto --dry-run=client -o yaml | kubectl apply -f -
```

```bash
kubectl create secret generic mosquitto-auth \
  --namespace mosquitto \
  --from-literal=users='device_pubsub:DevicePassword1!,producer_sub:ProducerPassword1!,online_receiver_sub:OnlineReceiverPassword1!,api_devices_pub:ApiDevicesPassword1!' \
  --dry-run=client -o yaml | kubectl apply -f -
```

```bash
kubectl apply -f local-example-k8s.yaml
kubectl rollout status deployment/mosquitto -n mosquitto
```

## Verify

```bash
kubectl get pods -n mosquitto
kubectl logs -n mosquitto deployment/mosquitto --tail=80
```

## Test MQTT

Terminal 1:

```bash
kubectl port-forward -n mosquitto svc/mosquitto 1883:1883
```

Terminal 2:

```bash
mosquitto_sub -h localhost -p 1883 \
  -u producer_sub -P 'ProducerPassword1!' \
  -t 'sensors/+/+'
```

Terminal 3:

```bash
mosquitto_pub -h localhost -p 1883 \
  -u device_pubsub -P 'DevicePassword1!' \
  -t 'sensors/test-device/temperature' \
  -m '{"value":21.5}'
```

Terminal 2 should receive:

```text
{"value":21.5}
```

## Cleanup

```bash
kubectl delete namespace mosquitto
```

```bash
kind delete cluster --name kind-cluster
```
