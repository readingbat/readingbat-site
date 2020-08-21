default: versioncheck

clean:
	./gradlew clean

compile:
	./gradlew build -xtest

build: compile

uberjar:
	./gradlew uberjar

uber: uberjar
	java -jar build/libs/server.jar

cc:
	./gradlew classes --continuous -x test

run:
	./gradlew run

versioncheck:
	./gradlew dependencyUpdates

upgrade-wrapper:
	./gradlew wrapper --gradle-version=6.6 --distribution-type=bin

heroku:
	git push heroku master

test-heroku:
	git push test master

restart:
	heroku restart --app readingbat

test-restart:
	heroku restart --app test-readingbat

shell:
	heroku ps:exec

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