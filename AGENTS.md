# AGENTS.md

This file provides guidance to coding agents when working with code in this repository.

## Project Overview

Containerized MQTT broker (Eclipse Mosquitto) with a custom Go entrypoint that handles dynamic authentication setup via environment variables. Part of the home-anthill IoT ecosystem. Published to Docker Hub as `ks89/mosquitto`.

The entrypoint (`entrypoint.go`) is a single-file Go program using only the standard library. It reads credentials from environment variables, validates them for security, creates a password file via `mosquitto_passwd`, and then execs into Mosquitto. It supports either the legacy single-user `MOSQUITTO_USERNAME` / `MOSQUITTO_PASSWORD` pair or multi-user `MOSQUITTO_USERS` (`username:password,username:password`) for role-based ACL deployments. The module is defined in `go.mod` (Go 1.26) but has no external dependencies.

## Architecture

**Multi-stage Docker build:**
1. **Builder stage** (`golang:1.26-alpine`): Compiles `entrypoint.go` into a static binary.
2. **Runtime stage** (`dhi.io/eclipse-mosquitto:2` — hardened image): Copies the binary and uses it as the container entrypoint.

**Startup flow** (`entrypoint.go`):
1. Reads `MOSQUITTO_USERS` or the legacy `MOSQUITTO_USERNAME` / `MOSQUITTO_PASSWORD` env vars, then immediately clears them from the environment.
2. Validates inputs: rejects usernames that start with `-`, contain path separators, colons, whitespace, or control characters; rejects passwords containing control characters.
3. If credentials are set, creates a password file at `/mosquitto/passwd/password_file` via `mosquitto_passwd` (password piped via stdin, not passed as CLI argument) and chmods it to 0600.
4. `syscall.Exec`s into `mosquitto -c /mosquitto/config/mosquitto.conf`.

**Mosquitto config** (`mosquitto-local-dev.conf`): Listens on port 1883, persistence enabled at `/mosquitto/data/`, anonymous connections disabled, password file at `/etc/mosquitto/password_file`.

**Security highlights** (`entrypoint.go`):
- Usernames are validated: leading `-`, `/\:` separators, whitespace, and control characters are rejected.
- Passwords are validated: control characters are rejected, including null bytes, tabs, carriage returns, and newlines.
- Credentials are cleared from the process environment immediately after reading, before any other work.
- The password is passed to `mosquitto_passwd` via stdin, not as a CLI argument, to avoid exposure in process listings.
- `MOSQUITTO_USERS` enables role-based broker users for Helm ACL deployments.
- Credential validation is covered by unit tests in `entrypoint_test.go`.

## Development Commands

The `Makefile` provides these targets:

```bash
make deps    # Install linting/analysis tools (shadow, staticcheck, govulncheck)
make lint    # Run staticcheck (replaces deprecated golint)
make vet     # Run go vet and shadow analysis for unused variables
make check   # Check for known vulnerabilities with govulncheck
make build   # Default target; runs lint, vet, and go build (not explicitly shown but runs all)
```

All targets run the Go toolchain locally — no Docker needed for development iteration.

## Testing & Verification

### Local Docker testing

Build and run the image locally:

```bash
# Build the image
docker build -t ks89/mosquitto:local .

# Prepare local data directories
mkdir -p data log

# Run with authentication
docker run -it --name mosquitto \
    -p 1883:1883 -p 9001:9001 \
    --rm \
    -v ./mosquitto-local-dev.conf:/mosquitto/config/mosquitto.conf:ro \
    -v ./mosquitto-local-acl.conf:/mosquitto/acl/acl_file:ro \
    -v ./data:/mosquitto/data \
    -v ./log:/mosquitto/log \
    -e MOSQUITTO_USERS='device_pubsub:DevicePassword1!,producer_sub:ProducerPassword1!,online_receiver_sub:OnlineReceiverPassword1!,api_devices_pub:ApiDevicesPassword1!' \
    ks89/mosquitto:local
```

### Smoke test (requires `mosquitto` CLI tools)

Install the CLI clients:
```bash
brew install mosquitto
```

Test authentication is working:
```bash
# This should succeed (exit code 0)
mosquitto_pub -h localhost -p 1883 -u device_pubsub -P 'DevicePassword1!' -t "sensors/test-device/temperature" -m '{"value":21.5}' && echo "OK"

# This should fail with "not authorised"
mosquitto_pub -h localhost -p 1883 -t "sensors/test-device/temperature" -m "hello"
```

Full testing guide (subscribe/publish across terminals): `LOCAL_GUIDE_DOCKER.md`

## CI/CD

GitHub Actions workflow (`.github/workflows/docker-image.yml`) builds and pushes to Docker Hub on pushes to `master`, `develop`, `ft**` branches, and `v*.*.*` tags. Uses Docker Buildx with GitHub Actions cache. The publish job depends on the test/check job, so images are only published after lint, vet, vulnerability checks, and build verification pass.

## Branch Conventions

- `master`: main/release branch
- `develop`: active development
- `ft**`: feature branches

## Local Kubernetes Deployment

For Kubernetes deployment on a local kind cluster or Docker Desktop:

- Docker Desktop Kubernetes and kind are separate clusters with independent kubeconfig contexts.
- The kind cluster must be created explicitly; enabling Kubernetes in Docker Desktop does not create a kind cluster.
- The project uses kind clusters named `kind-cluster` (kubeconfig context: `kind-kind-cluster`).

Quick start:
```bash
# Build and save the image
docker build -t ks89/mosquitto:local .
docker save ks89/mosquitto:local -o mosquitto.tar

# Create and load into kind
kind create cluster --name kind-cluster --image kindest/node:v1.32.0
kind load image-archive mosquitto.tar --name kind-cluster

# Deploy using the manifest
kubectl apply -f local-example-k8s.yaml
```

For the full guide including networking setup, secret management, and testing: `LOCAL_GUIDE_K8S.md`
