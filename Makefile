.PHONY: default help clean clean-all build tests uberjar run-uber cc run versioncheck lint detekt detekt-baseline format \
		docker-push release deploy do-log upgrade-wrapper _require-version _require-gradle-version

VERSION := $(shell sed -n 's/^version=\(.*\)/\1/p' gradle.properties)
GRADLE_VERSION := $(shell sed -n 's/^gradle = "\(.*\)"/\1/p' gradle/libs.versions.toml)

PLATFORMS := linux/amd64,linux/arm64
IMAGE_NAME := pambrose/readingbat

default: versioncheck

help:  ## Show this help (list of targets)
	@awk 'BEGIN {FS = ":.*?## "; printf "Usage: make <target>\n\nTargets:\n"} \
		/^[a-zA-Z0-9_-]+:.*?## / {printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

clean: ## Remove Gradle build outputs
	./gradlew clean

clean-all: clean ## Remove Gradle build outputs and caches
	rm -rf build .gradle

build: clean ## Clean and build (skipping tests)
	./gradlew build -x test

lint: ## Run Kotlinter and detekt
	./gradlew lintKotlin detekt

format: ## Apply kotlinter formatting fixes
	./gradlew formatKotlin

detekt: ## Run detekt static analysis
	./gradlew detekt

detekt-baseline: ## Generate detekt baseline file
	./gradlew detektBaseline

tests: ## Run the full test suite
	./gradlew --rerun-tasks check

uberjar: ## Build the fat/uber JAR
	./gradlew buildFatJar

run-uber: uberjar ## Run the built uber JAR
	java -jar build/libs/server.jar

cc: ## Continuous compile (classes, skip tests)
	./gradlew classes --continuous -x test

run: ## Run the app via Gradle
	./gradlew run

versioncheck: ## Report available dependency updates
	./gradlew dependencyUpdates

docker-push: _require-version ## Build and push multi-arch Docker image
	# prepare multiarch
	docker buildx use readingbat-builder 2>/dev/null || docker buildx create --use --name=readingbat-builder
	docker buildx build --platform $(PLATFORMS) --push -t $(IMAGE_NAME):latest -t $(IMAGE_NAME):$(VERSION) .

release: clean build uberjar docker-push ## Clean, build, package, and push Docker image
	@command -v say >/dev/null && say "finished app release" || true

deploy: ## Deploy the app via secrets/deploy-app.sh
	./secrets/deploy-app.sh
	@command -v say >/dev/null && say "finished app deployment" || true

do-log: ## Tail the deployed app log
	./secrets/app-log.sh

upgrade-wrapper: _require-gradle-version ## Upgrade the Gradle wrapper to the pinned version
	./gradlew wrapper --gradle-version=$(GRADLE_VERSION) --distribution-type=bin

_require-version:
	@[ -n "$(VERSION)" ] || { echo "ERROR: Could not determine project version from gradle.properties" >&2; exit 1; }

_require-gradle-version:
	@[ -n "$(GRADLE_VERSION)" ] || { echo "ERROR: Could not determine gradle version from gradle/libs.versions.toml" >&2; exit 1; }
