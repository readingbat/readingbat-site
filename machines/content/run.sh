#!/bin/bash

# A named volume so an OOM heap dump outlives the container, which --rm would otherwise discard.
# Not a bind mount: Docker would create the host directory as root and this image runs as uid 1000,
# so the JVM could not write there. A named volume inherits /app/dumps's ownership from the image.
# Retrieve a dump with:
#   docker run --rm -v readingbat-dumps:/dumps -v "$(pwd)":/out alpine cp /dumps/java_pid1.hprof /out/
docker run --rm -d --env-file=docker_env_vars -v readingbat-dumps:/app/dumps -p 8080:8080 pambrose/readingbat:3.4.0
