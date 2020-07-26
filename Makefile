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
	heroku restart -a readingbat

test-heroku:
	git push test test:master

logs:
	heroku logs --app=readingbat --tail

testlogs:
	heroku logs --app=testingbat --tail

clean-heroku:
	heroku repo:gc --app readingbat
	heroku repo:purge_cache --app readingbat

versioncheck:
	./gradlew dependencyUpdates