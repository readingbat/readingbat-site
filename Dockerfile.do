FROM gradle:jdk14 as builder

COPY --chown=gradle:gradle . /home/gradle/src
WORKDIR /home/gradle/src
RUN gradle clean
RUN gradle build -xtest
RUN gradle uberjar

# 
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

COPY --from=builder /home/gradle/src/build/libs/server.jar /app/server.jar
COPY ./resources /app/resources
COPY ./src/Content.kt /app/src/Content.kt
COPY /jmx /app/jmx
WORKDIR /app

EXPOSE 8080
EXPOSE 8081
EXPOSE 8083
EXPOSE 8091
EXPOSE 8092
EXPOSE 8093

CMD []
# Launch java to execute the jar with defaults intended for containers.
ENTRYPOINT ["java", "-server", "-XX:+UseContainerSupport", "-Xmx2048m", "-Dkotlin.script.classpath=/app/server.jar", "-javaagent:/app/jmx/jmx_prometheus_javaagent-0.14.0.jar=8081:/app/jmx/config.yaml", "-jar", "/app/server.jar"]

# CMD ["sh", "-c", "java -server -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap -XX:InitialRAMFraction=2 -XX:MinRAMFraction=2 -XX:MaxRAMFraction=2 -XX:+UseG1GC -XX:MaxGCPauseMillis=100 -XX:+UseStringDeduplication -jar KtorEasy.jar"]