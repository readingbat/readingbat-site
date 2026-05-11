# ReadingBat Site

[![Kotlin](https://img.shields.io/badge/language-Kotlin-7F52FF.svg?logo=kotlin&logoColor=white)](https://kotlinlang.org/)
[![JDK](https://img.shields.io/badge/JDK-21-007396.svg?logo=openjdk&logoColor=white)](https://adoptium.net/)
[![Ktor](https://img.shields.io/badge/Ktor-3.4-087CFA.svg?logo=ktor&logoColor=white)](https://ktor.io/)
[![Gradle](https://img.shields.io/badge/Gradle-9.5-02303A.svg?logo=gradle&logoColor=white)](https://gradle.org/)
[![License](https://img.shields.io/github/license/readingbat/readingbat-site.svg)](LICENSE.txt)
[![GitHub release](https://img.shields.io/github/v/release/readingbat/readingbat-site.svg?logo=github)](https://github.com/readingbat/readingbat-site/releases)
[![Docker Pulls](https://img.shields.io/docker/pulls/pambrose/readingbat.svg?logo=docker&logoColor=white)](https://hub.docker.com/r/pambrose/readingbat)
[![Docker Image Size](https://img.shields.io/docker/image-size/pambrose/readingbat/latest.svg?logo=docker&logoColor=white)](https://hub.docker.com/r/pambrose/readingbat)
[![Last commit](https://img.shields.io/github/last-commit/readingbat/readingbat-site.svg?logo=github)](https://github.com/readingbat/readingbat-site/commits/master)

The deployable content host for [readingbat.com](https://readingbat.com). This
repo is intentionally thin: the web server, routing, persistence, and challenge
runtime all live in [`readingbat-core`](https://github.com/readingbat/readingbat-core),
which is consumed here as a binary dependency. What lives in this repo is the
*content composition* and the deployment plumbing around it.

## Site Content

- [Top-level `Content.kt`](src/main/kotlin/Content.kt) — composes the full site
- [Java and Kotlin content](https://github.com/readingbat/readingbat-java-content/blob/master/src/main/kotlin/Content.kt)
- [Python content](https://github.com/readingbat/readingbat-python-content/blob/master/src/Content.kt)

## Code Content Repos

- [Java and Kotlin](https://github.com/readingbat/readingbat-java-content)
- [Python](https://github.com/readingbat/readingbat-python-content)

## Requirements

- JDK 21 (the Gradle toolchain will resolve one via [foojay](https://foojay.io/) if you don't already have it)
- Docker + `buildx` (only needed for releases)

All other versions — Gradle, Kotlin, Ktor, plugins — are pinned in
[`gradle/libs.versions.toml`](gradle/libs.versions.toml).

## Build and run

```bash
./gradlew run                # run the app locally
./gradlew build -x test      # build without tests
./gradlew buildFatJar        # produce build/libs/server.jar
java -jar build/libs/server.jar
```

The app listens on `8080` (HTTP) by default, with additional ports for JMX and
metrics — see the [`Dockerfile`](Dockerfile) for the full list.

## Test

```bash
./gradlew check              # full verification (tests + lint)
./gradlew test               # tests only
```

Tests use [Kotest](https://kotest.io) `StringSpec`. Test sources live under
`src/test/kotlin/com/readingbat/`.

## Lint and format

```bash
./gradlew lintKotlin detekt  # static analysis + style check
./gradlew formatKotlin       # apply ktlint fixes
```

Project formatting rules are in [`.editorconfig`](.editorconfig).

## Makefile shortcuts

Most common workflows have a `make` target. Run `make help` for the full list:

```bash
make build                   # clean and build (no tests)
make tests                   # full test suite
make lint                    # lintKotlin + detekt
make format                  # apply formatting
make uberjar                 # build the fat jar
make run-uber                # run the fat jar
make release                 # build + push multi-arch Docker image
make deploy                  # deploy via secrets/deploy-app.sh
make upgrade-wrapper         # bump the Gradle wrapper to the catalog-pinned version
```

## Docker

The image is built from `eclipse-temurin:21-jdk-alpine`, runs as a non-root
`readingbat` user, and declares a `HEALTHCHECK` on `/ping`. `make release`
publishes a multi-arch (`linux/amd64,linux/arm64`) image to
`pambrose/readingbat:{latest,$VERSION}`.

A multi-instance local composition is provided in
[`docker-compose.yml`](docker-compose.yml).

## Releasing and deploying

1. Bump `version=` in `gradle.properties`.
2. Move `[Unreleased]` entries in [`CHANGELOG.md`](CHANGELOG.md) under the new
   version and add a highlights entry to [`RELEASE_NOTES.md`](RELEASE_NOTES.md).
3. `make release` to build and push the Docker image.
4. Follow the runbook in [`docs/release_notes.md`](docs/release_notes.md) to
   roll the deployment on Digital Ocean.
5. Cut a GitHub release: tag `X.Y.Z` (no `v` prefix), title `vX.Y.Z`.

## Project conventions

See [`CLAUDE.md`](CLAUDE.md) for repo conventions (layout, version-catalog
discipline, Kotest patterns, configuration-cache safety) — useful for both
humans and AI coding agents.

## License

Apache License 2.0 — see [`LICENSE.txt`](LICENSE.txt).
