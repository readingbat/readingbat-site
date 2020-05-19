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

clean-heroku:
	heroku repo:gc --app readingbat
    heroku repo:purge_cache --app readingbat

logs:
	heroku logs --tail

versioncheck:
	./gradlew dependencyUpdates