FROM adoptopenjdk/openjdk14:alpine-jre

# Define the user to use in this instance to prevent using root that even in a container, can be a security risk.
ENV APPLICATION_USER readingbat

ENV AGENT_CONFIG resources/application.conf

# Then add the user, create the /app folder and give permissions to our user.
RUN adduser -D -g '' $APPLICATION_USER
RUN mkdir /app
RUN chown -R $APPLICATION_USER /app

# Mark this container to use the specified $APPLICATION_USER
USER $APPLICATION_USER

COPY ./build/libs/server.jar /app/server.jar
COPY ./resources /app/resources
COPY ./src/Content.kt /app/src/Content.kt
WORKDIR /app

EXPOSE 8080

CMD []
# Launch java to execute the jar with defaults intended for containers.
ENTRYPOINT ["java", "-server", "-XX:+UnlockExperimentalVMOptions", "-XX:+UseG1GC", "-XX:MaxGCPauseMillis=100", "-XX:+UseStringDeduplication", "-Dkotlin.script.classpath=/app/server.jar", "-jar", "/app/server.jar"]