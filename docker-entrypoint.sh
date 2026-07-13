#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# Copyright (c) 2026 EarthSpark Meter Ops LLC
#
# Translate SPARKNET_HTTP_* environment variables into sparknet-http CLI flags,
# so callers (compose, ansible, docker run) configure
# the service declaratively with env vars. If explicit args are passed to the
# container, they override this entirely.
set -eu

if [ "$#" -gt 0 ]; then
  exec /usr/local/bin/sparknet-http "$@"
fi

set -- --bind "${SPARKNET_HTTP_BIND:-0.0.0.0:8080}"

if [ -n "${SPARKNET_HTTP_GATEWAY_TYPE:-}" ]; then
  set -- "$@" --gateway-type "$SPARKNET_HTTP_GATEWAY_TYPE"
fi

case "${SPARKNET_HTTP_SIMULATE_GATEWAY:-}" in
  1|true|TRUE|yes|on)
    set -- "$@" --simulate-gateway
    ;;
  *)
    if [ -n "${SPARKNET_HTTP_DEVICE:-}" ]; then
      set -- "$@" --device "$SPARKNET_HTTP_DEVICE"
    fi
    if [ -n "${SPARKNET_HTTP_RESET_METHOD:-}" ]; then
      set -- "$@" --reset-method "$SPARKNET_HTTP_RESET_METHOD"
    fi
    if [ -n "${SPARKNET_HTTP_BOOTLOADER_METHOD:-}" ]; then
      set -- "$@" --bootloader-method "$SPARKNET_HTTP_BOOTLOADER_METHOD"
    fi
    ;;
esac

if [ -n "${SPARKNET_HTTP_BAUD:-}" ]; then
  set -- "$@" --baud "$SPARKNET_HTTP_BAUD"
fi
if [ -n "${SPARKNET_HTTP_HEARTBEAT:-}" ]; then
  set -- "$@" --heartbeat "$SPARKNET_HTTP_HEARTBEAT"
fi
if [ -n "${SPARKNET_HTTP_STATE_FILE:-}" ]; then
  set -- "$@" --state-file "$SPARKNET_HTTP_STATE_FILE"
fi
case "${SPARKNET_HTTP_FORCE_UPDATE:-}" in
  1|true|TRUE|yes|on) set -- "$@" --force-update ;;
esac

exec /usr/local/bin/sparknet-http "$@"
