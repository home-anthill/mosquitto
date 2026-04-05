# Running Mosquitto on a Local Kubernetes Cluster (Docker Desktop on macOS)

This guide shows how to deploy the `ks89/mosquitto` container on a local Kubernetes cluster using Docker Desktop on macOS.

It is a simplified, non-TLS version of the production Helm templates — suitable for local development and testing.


## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed on macOS (includes Docker engine)
  - Kubernetes enabled in Docker Desktop (Settings > Kubernetes > enable the built-in Kind cluster, if required)
- `kubectl` configured to talk to the Docker Desktop cluster (`kubectl config current-context` should show the Kind cluster)


### Building and loading the image

```bash
# Build the image with Docker
docker build -t ks89/mosquitto .

# Save the image as a tarball
docker save ks89/mosquitto -o mosquitto.tar

# Create a Kind cluster
kind create cluster --name kind-cluster --image kindest/node:v1.35.0

# Load it into the Kind cluster
kind load image-archive mosquitto.tar --name kind-cluster

# Clean up the tarball
rm mosquitto.tar
```

Alternatively, you can load the image directly from Docker Desktop's **Images** section by pushing it to the Kind cluster.


## Deploy

Apply the demo k8s manifest called `local-example-k8s.yaml`:

```bash
kubectl apply -f local-example-k8s.yaml
```


## Create the credentials Secret

Store the MQTT credentials in a Kubernetes Secret instead of passing them as plain-text env vars in the manifest:

```bash
kubectl create secret generic mosquitto-auth \
  --namespace mosquitto \
  --from-literal=username=mosquser \
  --from-literal=password='Password1!'
```


## Verify the deployment

You can verify either via the CLI or through Docker Desktop's UI.


### Via CLI

```bash
# Check pod status
kubectl get pods -n mosquitto

# View logs
kubectl logs -n mosquitto deployment/mosquitto

# You should see:
#   Configuring authentication
#   <mosquitto startup messages>
```


## Connect from your machine

Forward the MQTT port to localhost:

```bash
# Forward the port (Terminal 1)
kubectl port-forward -n mosquitto svc/mosquitto 1883:1883
```

Then in another terminals, test with the Mosquitto CLI tools (`brew install mosquitto`):

```bash
# Subscribe (Terminal 2)
mosquitto_sub -h localhost -p 1883 -u mosquser -P 'Password1!' -t "test/topic"

# Publish (Terminal 3)
mosquitto_pub -h localhost -p 1883 -u mosquser -P 'Password1!' -t "test/topic" -m "hello from k8s"
```

You should see `hello from k8s` appear in Terminal 1.


## Cleanup

```bash
kubectl delete namespace mosquitto
```

This removes all resources (deployment, service, configmap, secret, PVC) in one command.

To also remove the Kind cluster:

```bash
kind delete cluster --name kind-cluster
```