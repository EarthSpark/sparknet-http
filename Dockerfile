# syntax=docker/dockerfile:1
# SPDX-License-Identifier: Apache-2.0
# Copyright (c) 2026 EarthSpark Meter Ops LLC
#
# This Dockerfile is Apache-2.0. The sparknet-http binary it packages is NOT:
# it is proprietary and licensed under EULA.txt. See NOTICE.

# busybox:musl: the server binaries are statically linked (musl), so no libc is
# needed; busybox provides /bin/sh for the entrypoint and wget for the healthcheck.
FROM busybox:musl

# buildx sets TARGETARCH (amd64, arm64, ...) per platform in a multi-arch build.
# CI stages the matching Linux server binary at binaries/<TARGETARCH>/sparknet-http
# before building; see .github/workflows/build-image.yml.
ARG TARGETARCH
COPY binaries/${TARGETARCH}/sparknet-http /usr/local/bin/sparknet-http
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

# The license terms travel with the image: a recipient who never sees this
# repository still gets the binary's EULA, the Apache-2.0 text covering the
# packaging, and the GPLv2 written offer for the BusyBox source.
COPY LICENSE NOTICE EULA.txt THIRD-PARTY-NOTICES.txt /usr/share/licenses/sparknet-http/

# The image as a whole is not Apache-2.0 -- the binary in it is proprietary --
# so the licenses label names the EULA. Left unset, scanners infer Apache-2.0
# from the source repository, which would be wrong.
LABEL org.opencontainers.image.licenses="LicenseRef-EarthSpark-sparknet-http-EULA" \
      org.opencontainers.image.vendor="EarthSpark Meter Ops LLC" \
      org.opencontainers.image.title="sparknet-http" \
      org.opencontainers.image.description="SparkNet controller core with an HTTP + SSE API (proprietary; see /usr/share/licenses/sparknet-http/EULA.txt)" \
      org.opencontainers.image.source="https://github.com/EarthSpark/sparknet-http"

EXPOSE 8080
ENTRYPOINT ["/bin/sh", "/usr/local/bin/docker-entrypoint.sh"]
