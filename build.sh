#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Copyright (c) 2026 EarthSpark Meter Ops LLC
#
# Build the sparknet-http container image for one architecture from a
# locally-staged binary.
set -euo pipefail
cd "$(dirname "$0")"

IMAGE="${IMAGE:-ghcr.io/earthspark/sparknet-http}"
VERSION="${VERSION:-dev}"
PLATFORM="${PLATFORM:-linux/amd64}"

# Stage the matching Linux server binary yourself first, e.g.:
#   mkdir -p binaries/amd64
#   cp sparknet-http-linux-x86_64 binaries/amd64/sparknet-http
ARCH="${PLATFORM##*/}"
if [[ ! -f "binaries/${ARCH}/sparknet-http" ]]; then
  echo "error: binaries/${ARCH}/sparknet-http not found (stage it for ${PLATFORM})" >&2
  exit 1
fi

docker buildx build --platform "$PLATFORM" \
  -t "${IMAGE}:${VERSION}" -t "${IMAGE}:latest" \
  --load .
