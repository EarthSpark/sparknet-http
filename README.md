# SparkNet-Http

SparkNet-Http is a standalone meter-driver service for SparkNet networks.
It connects to a supported gateway over a serial device and exposes three interfaces that can run at the same time:

- the legacy interface
- an HTTP API with Server-Sent Events
- gRPC

This release is intended for binary-only deployment.
No source build is required to use SparkNet-Http.

This repository is the distribution point: it publishes the released binaries and builds the container image.
The service source and the `.proto` contract are maintained separately.

## Included Binaries

Each release includes the following binaries:

- `sparknet-http-linux-x86_64` — Linux x86_64
- `sparknet-http-linux-arm64` — Linux arm64
- `sparknet-http-linux-armv7` — Linux armv7
- `sparknet-http-macos-x86_64` — macOS Intel
- `sparknet-http-macos-arm64` — macOS Apple Silicon

Choose the binary that matches your target system, make it executable, and run it from the command line.

## Starting SparkNet-Http

Example:

```bash
./sparknet-http \
  --device /dev/tty.usbserial-AC00HIQ5 \
  --gateway-type firefly \
  --http-bind 127.0.0.1:18080 \
  --grpc-bind 127.0.0.1:50051
```

Common options:

- `--device` — serial device for the gateway
- `--gateway-type` — `rsrm`, `firefly`, or `emulator`
- `--http-bind` — HTTP API and SSE bind address
- `--grpc-bind` — gRPC bind address
- `--heartbeat` — default heartbeat duration in seconds
- `--simulate-gateway` — run without physical gateway hardware

If `--grpc-bind` is omitted, only the legacy and HTTP interfaces are active.
If `--http-bind` is omitted, the HTTP API is not exposed.

## First-Time Initialization

After startup, initialize SparkNet-Http by calling:

```
POST /v1/sparknet/init
```

This applies the network AES key, channel, and heartbeat period to the running service.

To discover the required initialization fields, call:

```
GET /v1/requirements
```

## Normal Operating Flow

The standard HTTP flow is:

1. Initialize SparkNet-Http with `POST /v1/sparknet/init`
2. Register each node with `POST /v1/nodes/register`
3. Configure meters with `POST /v1/meters/configure` or `POST /v1/nodes/{node_id}/configure-meter`
4. Read events from `GET /v1/events`

Useful routes:

- `GET /v1/healthz`
- `GET /v1/status`
- `GET /v1/events`
- `POST /v1/nodes/register`
- `DELETE /v1/nodes/{node_id}`
- `POST /v1/meters/configure`
- `POST /v1/commands`
- `GET /openapi.json`

## HTTP API Documentation

The public HTTP interface is described by:

```
GET /openapi.json
```

This document includes the public HTTP routes, request payloads, and response schemas.

## Server-Sent Events

Live events are streamed from:

```
GET /v1/events
```

This stream includes gateway status, node registration, heartbeat statistics, meter readings, configuration acknowledgements, firmware version changes, and other runtime events.

## gRPC

When started with `--grpc-bind`, SparkNet-Http also exposes gRPC services for clients that prefer protobuf-based integration.
The current release includes:

- `sparknet_http.external.SparkNetHttpControl`
- `tc2.meter_driver.v1.MeterDriverControl`

## SparkMAC-Tools Mode

SparkNet-Http also includes HTTP-only maintenance routes for provisioning, diagnostics, and firmware update workflows.
These routes are disabled during normal operation and must be enabled explicitly:

```
POST /v1/sparknet/sparkmac-tools/enable
```

Available maintenance routes:

- `GET /v1/sparknet/sparkmac-tools/status`
- `POST /v1/sparknet/sparkmac-tools/meter/ping`
- `POST /v1/sparknet/sparkmac-tools/meter/provision`
- `POST /v1/sparknet/sparkmac-tools/meter/program`

When SparkMAC-tools mode is enabled, normal scheduled meter activity is paused.
Returning to normal operation requires an OS restart.

## Shutdown

To request a clean shutdown:

```
POST /v1/shutdown
```

## Notes

- SparkMAC-tools routes are HTTP-only.
- The legacy interface remains active for backward compatibility.

## Container image

Published to `ghcr.io/earthspark/sparknet-http`.
Every build gets the release version tag; stable releases also move `latest`, prereleases move `beta`.
The image is a statically-linked server binary on `busybox:musl` — a minimal base that provides `/bin/sh` for the entrypoint and `wget` for the healthcheck.

### Configuration (environment variables)

The entrypoint (`docker-entrypoint.sh`) translates `SPARKNET_HTTP_*` environment variables into the binary's CLI flags, so callers configure the service declaratively — no `command:` needed.
Explicit args passed to the container override the env mapping entirely.

| env var | flag | notes |
|---|---|---|
| `SPARKNET_HTTP_BIND` | `--bind` | default `0.0.0.0:8080` (entrypoint default; the binary's own default is localhost-only) |
| `SPARKNET_HTTP_SIMULATE_GATEWAY` | `--simulate-gateway` | truthy (`1`/`true`/`yes`/`on`); when set, the device/reset/bootloader vars are ignored |
| `SPARKNET_HTTP_DEVICE` | `--device` | serial device (must also be passed into the container) |
| `SPARKNET_HTTP_GATEWAY_TYPE` | `--gateway-type` | `rsrm` / `firefly` / `detect` / `emulator` |
| `SPARKNET_HTTP_RESET_METHOD` | `--reset-method` | `gpio:<state>,<pin>` / `dtr` / `rts` |
| `SPARKNET_HTTP_BOOTLOADER_METHOD` | `--bootloader-method` | same modes |
| `SPARKNET_HTTP_BAUD` | `--baud` | |
| `SPARKNET_HTTP_HEARTBEAT` | `--heartbeat` | |
| `SPARKNET_HTTP_STATE_FILE` | `--state-file` | |
| `SPARKNET_HTTP_FORCE_UPDATE` | `--force-update` | truthy |

For a real gateway, set `SPARKNET_HTTP_DEVICE` and pass that serial device into the container; otherwise set `SPARKNET_HTTP_SIMULATE_GATEWAY`.

## Building & publishing the image

`.github/workflows/build-image.yml` builds and pushes the image when a release is published (or on manual `workflow_dispatch` with a tag).
It downloads the release assets named `sparknet-http-linux-*`, stages each at `binaries/<docker-arch>/sparknet-http`, and runs a `buildx` build that `COPY`s `binaries/${TARGETARCH}/sparknet-http` per platform.
A container image holds machine code for one CPU architecture, so each arch needs its own natively built binary; a multi-arch tag is several per-arch images joined by a manifest list.

For a local single-arch test build, stage a binary and run `bash build.sh` (env overrides: `IMAGE`, `VERSION`, `PLATFORM`).

## License

Two licenses apply here, and the split matters if you redistribute anything.

**The packaging in this repository is [Apache-2.0](LICENSE).**
That covers the `Dockerfile`, `build.sh`, `docker-entrypoint.sh`, the workflow, and this README — each source file carries an `SPDX-License-Identifier: Apache-2.0` header.

**The `sparknet-http` binaries are not.**
They are proprietary software of EarthSpark Meter Ops LLC, licensed only under [EULA.txt](EULA.txt).
That applies to every binary asset attached to a release, on every platform, and to the `sparknet-http` executable inside the published container images.
The Apache-2.0 license — including its patent grant — extends to the packaging only, and grants no rights in the binaries or in the SparkNet protocol implementation.
The service source is not published.

[NOTICE](NOTICE) states the boundary in full; it is the file to read before redistributing.
The container images also include third-party software under its own terms, including BusyBox under GPLv2 — see [THIRD-PARTY-NOTICES.txt](THIRD-PARTY-NOTICES.txt), which carries the written offer for corresponding source that license requires.

All four documents are attached to every release and are copied into the image at `/usr/share/licenses/sparknet-http/`, so they reach recipients who never see this repository.
