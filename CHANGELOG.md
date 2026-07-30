# Changelog

## 5.0.0

### Features

- Renamed the presence subscriber MQTT example user from `online_receiver_sub` to `alarm_receiver_sub`; its `online/+/features/+` ACL is unchanged.
- Allowed the shared device role to publish and `alarm_receiver_sub` to read `alarms/+/features/+/+`.

### Chores

- update deps


## 4.0.0

### Security Fixes

- **Multiple MQTT users supported** (2026-05-01): Added `MOSQUITTO_USERS` support using comma-separated `username:password` entries so deployments can generate one Mosquitto password file with role-specific users.
- **Single-user mode retained** (2026-05-01): Existing `MOSQUITTO_USERNAME` / `MOSQUITTO_PASSWORD` behavior remains supported for local and backward-compatible deployments, but it cannot be combined with `MOSQUITTO_USERS`.
- **Container restart fixed** (2026-05-01): The entrypoint now removes a previously generated password file before calling `mosquitto_passwd -c`, so Kubernetes container restarts with an existing `emptyDir` password file do not fail.
- **Password control characters rejected** (2026-04-24): `MOSQUITTO_PASSWORD` now rejects all control characters, including null bytes, tabs, carriage returns, and newlines. This prevents line-oriented stdin confusion when passing the password to `mosquitto_passwd`.
- **Username option injection blocked** (2026-04-24): `MOSQUITTO_USERNAME` now rejects values starting with `-`, preventing usernames from being interpreted as `mosquitto_passwd` command-line options.
- **Input validation** (2026-03-31): Added validation for `MOSQUITTO_USERNAME` and `MOSQUITTO_PASSWORD` environment variables. Usernames containing null bytes, path separators (`/`, `\`), colons, spaces, tabs, or newlines are now rejected. Passwords containing null bytes are rejected.
- **Password no longer visible in process listing** (2026-03-31): Removed the `-b` flag from `mosquitto_passwd`. The password is now piped via stdin instead of being passed as a command-line argument, preventing exposure via `ps aux` or `/proc/<pid>/cmdline`.
- **Environment variables cleared earlier** (2026-03-31): Moved `os.Unsetenv("MOSQUITTO_USERNAME")` and `os.Unsetenv("MOSQUITTO_PASSWORD")` to immediately after reading the values, before any other work is done. Previously they were cleared after the password file was created.

### Bug Fixes

- **Removed unexplained 10-second sleep** (2026-03-31): Removed the `time.Sleep(10 * time.Second)` call that delayed startup unconditionally with no clear purpose. This also removes the window where the password file existed on disk but Mosquitto was not yet running.

### CI/CD Fixes

- **Publish waits for checks** (2026-04-24): The Docker image publish job now depends on the test/check job, ensuring images are only published after lint, vet, vulnerability checks, and build verification pass.

### Tests

- **Multiple-user parser tests added** (2026-05-01): Added unit coverage for parsing multiple MQTT users.
- **Credential validation tests added** (2026-04-24): Added unit tests covering accepted and rejected username/password cases.

### Documentation

- **Local guides updated** (2026-05-01): Docker and Kubernetes local guides now use `MOSQUITTO_USERS` plus ACL files that match the production role split.

### Troubleshooting

- **`kind load image-archive` failing** (2026-03-31): `kind load image-archive mosquitto.tar` fails with "no nodes found for cluster 'kind'" when the kind cluster does not exist, even if a stale kubeconfig context (`kind-kind-cluster`) remains.
- **Fix** (2026-03-31): Create the kind cluster first with `kind create cluster --name kind-cluster --image kindest/node:v1.32.0`, then switch context with `kubectl config use-context kind-kind-cluster`, then run `kind load image-archive mosquitto.tar --name kind-cluster`.
- **Note** (2026-03-31): Docker Desktop Kubernetes and kind are independent. Enabling Kubernetes in Docker Desktop does not create a kind cluster.
