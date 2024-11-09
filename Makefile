VERSION=1.16.1

default: versioncheck

clean:
	./gradlew clean

compile: clean
	./gradlew build -xtest

build: compile

pull:
	git pull

deploy: pull distro docker

tests:
	./gradlew --rerun-tasks check

uberjar:
	./gradlew uberjar

run-uber: uberjar
	java -jar build/libs/server.jar

distro: clean build uberjar

docker: build-docker push-docker

cc:
	./gradlew classes --continuous -x test

run:
	./gradlew run

versioncheck:
	./gradlew dependencyUpdates

#build-docker:
#	docker build -t pambrose/readingbat:${VERSION} .
#
#run-docker:
#	docker run --rm --env-file=docker_env_vars -p 8080:8080 pambrose/readingbat:${VERSION}

#push-docker:
#	docker push pambrose/readingbat:${VERSION}

PLATFORMS := linux/amd64,linux/arm64/v8
IMAGE_NAME := pambrose/readingbat

docker-push:
	# prepare multiarch
	docker buildx use buildx 2>/dev/null || docker buildx create --use --name=buildx
	docker buildx build --platform ${PLATFORMS} --push -t ${IMAGE_NAME}:latest -t ${IMAGE_NAME}:${VERSION} .

release: clean build uberjar docker-push

upgrade-wrapper:
	./gradlew wrapper --gradle-version=8.10.2 --distribution-type=bin