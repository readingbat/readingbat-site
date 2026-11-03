# Pinned to the multi-arch index digest so a rebuild of the same version gets the same JDK;
# Dependabot (.github/dependabot.yml) proposes the digest bumps that keep the base image patched.
FROM eclipse-temurin:25-jdk-alpine@sha256:425f0b733cb23843bd78dbe5552513976d0cf12b9722752c48a5161cf5cd2f32
LABEL maintainer="Paul Ambrose <pambrose@mac.com>"

# Define the user to use in this instance to prevent using root that even in a container, can be a security risk.
ENV APPLICATION_USER=readingbat

ENV AGENT_CONFIG=/app/src/main/resources/application.conf

# Capture a heap dump if the JVM dies of an OOM: a dump taken at the moment it happens is the only
# thing that says what was holding memory, and the flags cost nothing until then. /app/dumps is a
# mount point -- without a volume behind it the dump dies with the container. Note a dump is roughly
# the size of the live heap, and MaxRAMPercentage below allows 75% of the machine's RAM.
# ExitOnOutOfMemoryError then exits (after the dump is written) rather than leaving a JVM that has
# lost a thread to the OOM serving traffic; the restart policy brings up a fresh one. The JVM will
# not overwrite an existing java_pid1.hprof, so move each dump off the volume once retrieved, or the
# next OOM writes none.
ENV JAVA_TOOL_OPTIONS="-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/app/dumps -XX:+ExitOnOutOfMemoryError"

# Clear the base image's high CVEs: take the patched libexpat (only fontconfig uses it) from Alpine's
# repo ahead of a Temurin rebuild, and drop binutils, which Temurin ships for jlink and nothing here
# runs. libexpat's version then follows the build date rather than the digest. Re-check both on a
# digest bump: once the base image carries the fix, the upgrade is a no-op and can go.
RUN apk upgrade --no-cache libexpat && apk del --no-cache binutils

# Add the user and give it the dumps directory, the only place the server writes. Everything else
# under /app stays owned by root, so the server cannot modify its own jar, config, or Content.kt.
RUN adduser -D -H $APPLICATION_USER && mkdir -p /app/dumps && chown $APPLICATION_USER:$APPLICATION_USER /app/dumps

COPY src/main/kotlin/Content.kt /app/src/main/kotlin/Content.kt
COPY src/main/resources /app/src/main/resources
COPY jmx /app/jmx
COPY build/libs/server.jar /app/server.jar
WORKDIR /app

# Mark this container to use the specified $APPLICATION_USER
USER $APPLICATION_USER

# 8080 the server, 8081 the JMX exporter, 8083 and 8093 the Prometheus agent's metrics and admin servers
EXPOSE 8080 8081 8083 8093

# Shell form so the check follows the PORT override that application.conf honors.
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD wget -qO /dev/null "http://localhost:${PORT:-8080}/ping" || exit 1

# Launch java to execute the jar with defaults intended for containers.
# The JMX exporter jar is vendored in jmx/, so `make versions` does not see it; check
# https://github.com/prometheus/jmx_exporter/releases when refreshing dependencies.
ENTRYPOINT ["java", "-XX:MaxRAMPercentage=75", "-Dkotlin.script.classpath=/app/server.jar", "-Dlogback.configurationFile=/app/src/main/resources/logback.xml", "-javaagent:/app/jmx/jmx_prometheus_javaagent-1.7.0.jar=8081:/app/jmx/config.yaml", "-jar", "/app/server.jar"]
