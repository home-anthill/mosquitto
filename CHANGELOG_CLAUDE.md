# Changelog

## 2026-05-01

### Security Fixes (`entrypoint.go`)

- **Multiple MQTT users supported**: Added `MOSQUITTO_USERS` support using comma-separated `username:password` entries so deployments can generate one Mosquitto password file with role-specific users.
- **Single-user mode retained**: Existing `MOSQUITTO_USERNAME` / `MOSQUITTO_PASSWORD` behavior remains supported for local and backward-compatible deployments, but it cannot be combined with `MOSQUITTO_USERS`.
- **Container restart fixed**: The entrypoint now removes a previously generated password file before calling `mosquitto_passwd -c`, so Kubernetes container restarts with an existing `emptyDir` password file do not fail.
- **Multiple-user parser tests added**: Added unit coverage for parsing multiple MQTT users.
- **Local guides updated**: Docker and Kubernetes local guides now use `MOSQUITTO_USERS` plus ACL files that match the production role split.

## 2026-04-24

### Security Fixes (`entrypoint.go`)

- **Password control characters rejected**: `MOSQUITTO_PASSWORD` now rejects all control characters, including null bytes, tabs, carriage returns, and newlines. This prevents line-oriented stdin confusion when passing the password to `mosquitto_passwd`.
- **Username option injection blocked**: `MOSQUITTO_USERNAME` now rejects values starting with `-`, preventing usernames from being interpreted as `mosquitto_passwd` command-line options.
- **Credential validation tests added**: Added unit tests covering accepted and rejected username/password cases.

### CI/CD Fixes (`.github/workflows/docker-image.yml`)

- **Publish waits for checks**: The Docker image publish job now depends on the test/check job, ensuring images are only published after lint, vet, vulnerability checks, and build verification pass.

## 2026-03-31 (kind / Kubernetes)

### Troubleshooting: `kind load image-archive` failing

- **Root cause**: `kind load image-archive mosquitto.tar` fails with "no nodes found for cluster 'kind'" when the kind cluster does not exist, even if a stale kubeconfig context (`kind-kind-cluster`) remains.
- **Fix**: Create the kind cluster first with `kind create cluster --name kind-cluster --image kindest/node:v1.32.0`, then switch context with `kubectl config use-context kind-kind-cluster`, then run `kind load image-archive mosquitto.tar --name kind-cluster`.
- **Note**: Docker Desktop Kubernetes and kind are independent — enabling Kubernetes in Docker Desktop does not create a kind cluster.

## 2026-03-31

### Security Fixes (`entrypoint.go`)

- **Input validation**: Added validation for `MOSQUITTO_USERNAME` and `MOSQUITTO_PASSWORD` environment variables. Usernames containing null bytes, path separators (`/`, `\`), colons, spaces, tabs, or newlines are now rejected. Passwords containing null bytes are rejected.
- **Password no longer visible in process listing**: Removed the `-b` flag from `mosquitto_passwd`. The password is now piped via stdin instead of being passed as a command-line argument, preventing exposure via `ps aux` or `/proc/<pid>/cmdline`.
- **Environment variables cleared earlier**: Moved `os.Unsetenv("MOSQUITTO_USERNAME")` and `os.Unsetenv("MOSQUITTO_PASSWORD")` to immediately after reading the values, before any other work is done. Previously they were cleared after the password file was created.

### Bug Fixes (`entrypoint.go`)

- **Removed unexplained 10-second sleep**: Removed the `time.Sleep(10 * time.Second)` call that delayed startup unconditionally with no clear purpose. This also removes the window where the password file existed on disk but Mosquitto was not yet running.
