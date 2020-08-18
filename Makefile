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

heroku:
	git push heroku master

restart:
	heroku restart --app readingbat

test-heroku:
	git push test master

shell:
	heroku ps:exec

logs:
	heroku logs --app=readingbat --tail

test-logs:
	heroku logs --app=test-readingbat --tail

clean-heroku:
	heroku repo:gc --app readingbat
	heroku repo:purge_cache --app readingbat

versioncheck:
	./gradlew dependencyUpdates

upgrade-wrapper:
	./gradlew wrapper --gradle-version=6.6 --distribution-type=bin