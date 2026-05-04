FROM eclipse-temurin:21-jdk-alpine
LABEL maintainer="Paul Ambrose <pambrose@mac.com>"

# Define the user to use in this instance to prevent using root that even in a container, can be a security risk.
ENV APPLICATION_USER=readingbat

ENV AGENT_CONFIG=/app/src/main/resources/application.conf

# Then add the user, create the /app folder and give permissions to our user.
RUN adduser -D -H $APPLICATION_USER && mkdir /app && chown -R $APPLICATION_USER /app

# Mark this container to use the specified $APPLICATION_USER
USER $APPLICATION_USER

COPY --chown=$APPLICATION_USER:$APPLICATION_USER src/main/kotlin/Content.kt /app/src/main/kotlin/Content.kt
COPY --chown=$APPLICATION_USER:$APPLICATION_USER src/main/resources /app/src/main/resources
COPY --chown=$APPLICATION_USER:$APPLICATION_USER jmx /app/jmx
COPY --chown=$APPLICATION_USER:$APPLICATION_USER build/libs/server.jar /app/server.jar
WORKDIR /app

EXPOSE 8080 8081 8083 8091 8092 8093

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD wget -qO- http://localhost:8080/ping || exit 1

# Launch java to execute the jar with defaults intended for containers.
ENTRYPOINT ["java", "-server", "-XX:MaxRAMPercentage=75", "-Dkotlin.script.classpath=/app/server.jar", "-Dlogback.configurationFile=/app/src/main/resources/logback.xml", "-javaagent:/app/jmx/jmx_prometheus_javaagent-1.5.0.jar=8081:/app/jmx/config.yaml", "-jar", "/app/server.jar"]
