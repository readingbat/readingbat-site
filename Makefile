.PHONY: default help clean clean-all build tests uberjar run-uber cc run versions versions-all lint detekt \
		detekt-baseline format docker-push docker-verify release release-check _confirm-release deploy do-log \
		upgrade-wrapper _require-version _require-final-version _require-gradle-version

VERSION := $(shell sed -n 's/^version=\(.*\)/\1/p' gradle.properties)
GRADLE_VERSION := $(shell sed -n 's/^gradle-wrapper = "\(.*\)"/\1/p' gradle/libs.versions.toml)

PLATFORMS := linux/amd64,linux/arm64
IMAGE_NAME := pambrose/readingbat
DOCKER_HUB_TAGS_URL := https://hub.docker.com/v2/repositories/$(IMAGE_NAME)/tags
REPO_URL := https://github.com/readingbat/readingbat-site

# `make release` pushes only from a clean, up-to-date checkout of this branch whose GitHub CI has passed.
RELEASE_BRANCH ?= master
# The ci.yml jobs that must have passed for HEAD. Any other check run must not have failed either.
REQUIRED_CHECKS := build
# The files that pin $(IMAGE_NAME) to a tag. release-check fails unless every pin in each one is VERSION;
# keep this list in step with the "Versioning and releases" section of CLAUDE.md.
RELEASE_VERSION_FILES := docker-compose.yml machines/content/run.sh
# The commit `make release` started from; _confirm-release refuses to push if HEAD has moved since.
HEAD_SHA := $(shell git rev-parse HEAD 2>/dev/null)

default: help

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

# dependencyUpdates is marked incompatible with the configuration cache (build.gradle.kts), so a run with the cache on
# builds an entry only to discard it, and says so. --no-configuration-cache skips the cache for this run instead.
# build.gradle.kts gives the task a formatter that lists only what is behind; versions-all names the plugin's own plain
# report, which also lists everything up to date.
versions: ## List the dependencies with newer versions, and any that could not be checked
	./gradlew dependencyUpdates --no-configuration-cache --no-parallel

versions-all: ## The plugin's full dependency report, up-to-date dependencies included
	./gradlew dependencyUpdates --no-configuration-cache --no-parallel --output-formatter=plain

docker-push: _require-final-version uberjar ## Build and push multi-arch Docker image
	# prepare multiarch
	docker buildx use readingbat-builder 2>/dev/null || docker buildx create --use --name=readingbat-builder
	docker buildx build --platform $(PLATFORMS) --push -t $(IMAGE_NAME):latest -t $(IMAGE_NAME):$(VERSION) .

docker-verify: _require-version ## Check the published VERSION image has every platform in PLATFORMS, and latest matches
	@out=$$(docker buildx imagetools inspect $(IMAGE_NAME):$(VERSION)) || exit 1; \
	for platform in $$(echo $(PLATFORMS) | tr ',' ' '); do \
		echo "$$out" | grep -q "Platform: *$$platform" \
			|| { echo "ERROR: $(IMAGE_NAME):$(VERSION) is missing $$platform" >&2; exit 1; }; \
	done; \
	latest=$$(docker buildx imagetools inspect $(IMAGE_NAME):latest | grep -m1 '^Digest:'); \
	[ -n "$$latest" ] && [ "$$latest" = "$$(echo "$$out" | grep -m1 '^Digest:')" ] \
		|| { echo "ERROR: $(IMAGE_NAME):latest is not $(IMAGE_NAME):$(VERSION)" >&2; exit 1; }; \
	echo "$(IMAGE_NAME):$(VERSION) (and :latest) published for $(PLATFORMS)"

# Pushes nothing: it fails unless this checkout is fit to release VERSION. The local checks run first, then the
# network ones (origin, GitHub's CI checks for HEAD, Docker Hub). A network check that gets no clear answer fails.
release-check: _require-final-version ## Fail unless this checkout is fit to release VERSION
	@test -z "$$(git status --porcelain)" \
		|| { echo "ERROR: the working tree is dirty; commit or stash first" >&2; exit 1; }
	@branch=$$(git rev-parse --abbrev-ref HEAD); [ "$$branch" = "$(RELEASE_BRANCH)" ] \
		|| { echo "ERROR: releases are cut from $(RELEASE_BRANCH), not $$branch" >&2; exit 1; }
	@snapshots=$$(grep -n 'SNAPSHOT' gradle/libs.versions.toml | sed 's/^/  /'); [ -z "$$snapshots" ] \
		|| { printf 'ERROR: gradle/libs.versions.toml pins SNAPSHOT versions, so the image is not reproducible:\n%s\n' \
			"$$snapshots" >&2; exit 1; }
	@! grep -qE '^[[:space:]]*mavenLocal' settings.gradle.kts \
		|| { echo "ERROR: settings.gradle.kts resolves from mavenLocal(); disable it so the image uses only" \
			"published artifacts" >&2; exit 1; }
	@grep -q '^## \[$(VERSION)\]' CHANGELOG.md \
		|| { echo "ERROR: CHANGELOG.md has no [$(VERSION)] section" >&2; exit 1; }
	@grep -qE '^## v$(VERSION)( |$$)' RELEASE_NOTES.md \
		|| { echo "ERROR: RELEASE_NOTES.md has no v$(VERSION) section" >&2; exit 1; }
	@for f in $(RELEASE_VERSION_FILES); do \
		pins=$$(grep -oE '$(IMAGE_NAME):[^" ]+' "$$f"); \
		[ -n "$$pins" ] || { echo "ERROR: $$f pins no $(IMAGE_NAME) tag; update RELEASE_VERSION_FILES" >&2; exit 1; }; \
		stale=$$(echo "$$pins" | grep -vxF '$(IMAGE_NAME):$(VERSION)' | sort -u | sed 's/^/  /'); \
		[ -z "$$stale" ] || { printf 'ERROR: %s is not bumped to $(VERSION); it still pins:\n%s\n' \
			"$$f" "$$stale" >&2; exit 1; }; \
	done
	@docker info >/dev/null 2>&1 \
		|| { echo "ERROR: Docker isn't running; docker-push needs it" >&2; exit 1; }
	@git fetch -q --tags origin $(RELEASE_BRANCH) \
		|| { echo "ERROR: could not fetch $(RELEASE_BRANCH) and tags from origin" >&2; exit 1; }
	@[ "$$(git rev-parse HEAD)" = "$$(git rev-parse origin/$(RELEASE_BRANCH))" ] \
		|| { echo "ERROR: HEAD is not origin/$(RELEASE_BRANCH); pull or push first" >&2; exit 1; }
	@tagged=$$(git rev-parse -q --verify "refs/tags/$(VERSION)^{commit}"); \
	[ -z "$$tagged" ] || [ "$$tagged" = "$$(git rev-parse HEAD)" ] \
		|| { echo "ERROR: tag $(VERSION) points at another commit" >&2; exit 1; }
	@runs=$$(gh api "repos/{owner}/{repo}/commits/$$(git rev-parse HEAD)/check-runs" --paginate \
		--jq '.check_runs[] | "\(.status) \(.conclusion) \(.name)"') \
		|| { echo "ERROR: could not read HEAD's CI checks from GitHub; is gh logged in?" >&2; exit 1; }; \
	for name in $(REQUIRED_CHECKS); do \
		echo "$$runs" | grep -qx "completed success $$name" \
			|| { echo "ERROR: CI check '$$name' has not passed for HEAD" >&2; exit 1; }; \
	done; \
	failed=$$(echo "$$runs" | grep -Ev '^completed (success|skipped|neutral) ' | sed 's/^/  /'); \
	[ -z "$$failed" ] || { printf 'ERROR: CI has not passed for HEAD:\n%s\n' "$$failed" >&2; exit 1; }
	@code=$$(curl -s -o /dev/null -w '%{http_code}' "$(DOCKER_HUB_TAGS_URL)/$(VERSION)"); \
	case "$$code" in \
		404) ;; \
		200) echo "ERROR: $(IMAGE_NAME):$(VERSION) is already on Docker Hub; bump the version" >&2; exit 1;; \
		*) echo "ERROR: could not tell whether $(IMAGE_NAME):$(VERSION) is on Docker Hub (HTTP $$code)" >&2; exit 1;; \
	esac
	@echo "Ready to release $(VERSION) from $$(git rev-parse --short HEAD)"

# The tests take a while, so the checkout release-check passed is checked again before anything is pushed.
_confirm-release:
	@[ -n "$(RELEASE_SHA)" ] || { echo "ERROR: _confirm-release is run by make release" >&2; exit 1; }
	@test -z "$$(git status --porcelain)" \
		|| { echo "ERROR: the working tree changed during the release run; nothing was pushed" >&2; exit 1; }
	@[ "$$(git rev-parse HEAD)" = "$(RELEASE_SHA)" ] \
		|| { echo "ERROR: HEAD moved during the release run; nothing was pushed" >&2; exit 1; }
	@echo "About to push $(IMAGE_NAME):$(VERSION) and :latest for $(PLATFORMS),"
	@echo "built from $$(git rev-parse --short HEAD). This replaces :latest on Docker Hub."
	@printf 'Continue? [y/N] ' && read ans && [ "$$ans" = "y" ] || { echo "Nothing pushed."; exit 1; }

# Each step runs only if the one before it passed, so nothing is pushed until the checkout passes release-check,
# a clean run of the full test suite, and the confirmation. After a partial release, finish with the remaining
# targets (docker-push, docker-verify): release-check refuses a version that is already on Docker Hub.
release: ## Gate, test, then push and verify the VERSION image on Docker Hub (asks first)
	$(MAKE) release-check
	$(MAKE) clean
	$(MAKE) tests
	@$(MAKE) --no-print-directory _confirm-release RELEASE_SHA=$(HEAD_SHA)
	$(MAKE) docker-push
	$(MAKE) docker-verify
	@prev=$$(git describe --tags --abbrev=0 --exclude=$(VERSION) 2>/dev/null); \
	echo; \
	echo "Pushed $(IMAGE_NAME):$(VERSION) and :latest. Next:"; \
	echo "  1. Roll the deployment on Digital Ocean (docs/release_notes.md)"; \
	echo "  2. Create the GitHub release if it doesn't exist yet: tag $(VERSION), title v$(VERSION), and a summary"; \
	echo "     ending with **Full Changelog**: $(REPO_URL)/compare/$$prev...$(VERSION)"; \
	echo "     gh release create $(VERSION) --target $(HEAD_SHA) --title v$(VERSION) --notes-file <notes>"
	@command -v say >/dev/null && say "finished app release" || true

deploy: ## Deploy the app via secrets/deploy-app.sh
	./secrets/deploy-app.sh
	@command -v say >/dev/null && say "finished app deployment" || true

do-log: ## Tail the deployed app log
	./secrets/app-log.sh

upgrade-wrapper: _require-gradle-version ## Upgrade the Gradle wrapper to the catalog version
	# Gradle's documented upgrade procedure: the first run rewrites
	# gradle-wrapper.properties using the *old* wrapper jar; the second run
	# regenerates the wrapper itself with the new version.
	./gradlew wrapper --gradle-version=$(GRADLE_VERSION) --distribution-type=bin
	./gradlew wrapper --gradle-version=$(GRADLE_VERSION) --distribution-type=bin

_require-version:
	@[ -n "$(VERSION)" ] || { echo "ERROR: Could not determine project version from gradle.properties" >&2; exit 1; }

_require-final-version: _require-version
	@case "$(VERSION)" in *SNAPSHOT*|*-rc*|*-beta*|*-alpha*) \
		echo "ERROR: $(VERSION) is a pre-release; only final versions are pushed as :latest" >&2; exit 1;; esac

_require-gradle-version:
	@[ -n "$(GRADLE_VERSION)" ] || { echo "ERROR: Could not determine gradle version from gradle/libs.versions.toml" >&2; exit 1; }
