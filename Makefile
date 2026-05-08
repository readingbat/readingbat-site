VERSION=$(shell grep '^version=' gradle.properties | cut -d= -f2)
GRADLE_VERSION=$(shell grep '^gradle = ' gradle/libs.versions.toml | cut -d'"' -f2)

.PHONY: default clean clean-all build tests uberjar run-uber cc run versioncheck docker-push release deploy do-log upgrade-wrapper

default: versioncheck

clean:
	./gradlew clean

clean-all: clean
	rm -rf build .gradle

build: clean
	./gradlew build -xtest

tests:
	./gradlew --rerun-tasks check

uberjar:
	./gradlew buildFatJar

run-uber: uberjar
	java -jar build/libs/server.jar

cc:
	./gradlew classes --continuous -x test

run:
	./gradlew run

versioncheck:
	./gradlew dependencyUpdates

#build-docker:
#	docker build -t pambrose/readingbat:${VERSION}
#run-docker:
#	docker run --rm --env-file=docker_env_vars -p 8080:8080 pambrose/readingbat:${VERSION}

#push-docker:
#	docker push pambrose/readingbat:${VERSION}

PLATFORMS := linux/amd64,linux/arm64
IMAGE_NAME := pambrose/readingbat

docker-push:
	# prepare multiarch
	docker buildx use readingbat-builder 2>/dev/null || docker buildx create --use --name=readingbat-builder
	docker buildx build --platform ${PLATFORMS} --push -t ${IMAGE_NAME}:latest -t ${IMAGE_NAME}:${VERSION} .

release: clean build uberjar docker-push
	say finished app release

deploy:
	./secrets/deploy-app.sh
	say finished app deployment

do-log:
	./secrets/app-log.sh

upgrade-wrapper:
	./gradlew wrapper --gradle-version=$(GRADLE_VERSION) --distribution-type=bin