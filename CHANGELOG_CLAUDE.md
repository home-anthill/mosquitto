# Changelog

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
