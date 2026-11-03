#!/bin/bash

# The image exits on an OutOfMemoryError (after writing a heap dump), so the container needs a restart
# policy to come back up. Docker refuses --restart together with --rm, so a stopped container is left
# behind; remove it with `docker rm` before starting a new one on the same port.
# A named volume so an OOM heap dump outlives the container it was written in.
# Not a bind mount: Docker would create the host directory as root and this image runs as uid 1000,
# so the JVM could not write there. A named volume inherits /app/dumps's ownership from the image.
# Retrieve a dump with the command below. It moves the file off the volume rather than copying it: the
# JVM will not overwrite an existing java_pid1.hprof, so a dump left there means the next OOM writes none.
#   docker run --rm -v readingbat-dumps:/dumps -v "$(pwd)":/out alpine mv /dumps/java_pid1.hprof /out/
docker run -d --restart=unless-stopped --env-file=docker_env_vars -v readingbat-dumps:/app/dumps -p 8080:8080 pambrose/readingbat:3.6.1
