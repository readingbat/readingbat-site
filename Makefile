VERSION=1.0.27

default: versioncheck

clean:
	./gradlew clean

compile:
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

gcr: build-gcr push-gcr

cc:
	./gradlew classes --continuous -x test

run:
	./gradlew run

versioncheck:
	./gradlew dependencyUpdates

heroku:
	git push heroku master

test-heroku:
	git push test master

restart:
	heroku restart --app readingbat

test-restart:
	heroku restart --app test-readingbat

logs:
	heroku logs --app=readingbat --tail

test-logs:
	heroku logs --app=test-readingbat --tail

clean-heroku:
	heroku repo:gc --app readingbat
	heroku repo:purge_cache --app readingbat

visualvm:
	heroku java:visualvm --app readingbat

shell:
	heroku ps:exec --app readingbat

copy:
	# gzip head*
	heroku ps:copy --app readingbat /tmp/heapdump-1598156825426.hprof.gz


build-docker:
	docker build -t pambrose/readingbat:${VERSION} .

run-docker:
	docker run --rm --env-file=docker_env_vars -p 8080:8080 pambrose/readingbat:${VERSION}

push-docker:
	docker push pambrose/readingbat:${VERSION}

build-do:
	docker build -f Dockerfile.do -t pambrose/readingbat:${VERSION} .

build-gcr:
	docker build -t gcr.io/readingbat-1/readingbat:${VERSION} .

run-gcr:
	docker run --rm --env-file=docker_env_vars -p 8080:8080 gcr.io/readingbat-1/readingbat:${VERSION}

push-gcr:
	docker push gcr.io/readingbat-1/readingbat:${VERSION}

heroku-push:
	heroku container:push web --app docker-readingbat

heroku-release:
	heroku container:release web --app docker-readingbat

docker-logs:
	heroku logs --app=docker-readingbat --tail

docker-open:
	heroku open --app=docker-readingbat

upgrade-wrapper:
	./gradlew wrapper --gradle-version=6.8.1 --distribution-type=bin