VERSION=1.0.1

default: versioncheck

clean:
	./gradlew clean

compile:
	./gradlew build -xtest

build: compile

uberjar:
	./gradlew uberjar

run-uber: uberjar
	java -jar build/libs/server.jar

cc:
	./gradlew classes --continuous -x test

run:
	./gradlew run

versioncheck:
	./gradlew dependencyUpdates

upgrade-wrapper:
	./gradlew wrapper --gradle-version=6.6.1 --distribution-type=bin

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
	docker run --env-file=docker_env_vars -p 8080:8080 pambrose/readingbat:${VERSION}

push-docker:
	docker push pambrose/readingbat:${VERSION}

heroku-push:
	heroku container:push web --app docker-readingbat

heroku-release:
	heroku container:release web --app docker-readingbat

docker-logs:
	heroku logs --app=docker-readingbat --tail

docker-open:
	heroku open --app=docker-readingbat
