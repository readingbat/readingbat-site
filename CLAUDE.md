# CLAUDE.md

Project-specific guidance for Claude when working in this repo. User-level preferences
(commit policy, release/tag conventions, Kotest style) live in the user's global
`~/.claude/CLAUDE.md` and take precedence — this file fills in repo specifics.

## What this repo is

`readingbat-site` is the deployable content host for [readingbat.com](https://readingbat.com).
It is intentionally thin: the web server, routing, persistence, and challenge runtime all
live in [`readingbat-core`](https://github.com/readingbat/readingbat-core), which this repo
depends on as a binary artifact.

The site's *content* is assembled in `src/main/kotlin/Content.kt`, which pulls together
challenge definitions from external content repos:

- [`readingbat-java-content`](https://github.com/readingbat/readingbat-java-content) — Java + Kotlin
- [`readingbat-python-content`](https://github.com/readingbat/readingbat-python-content) — Python

The application entry point is `src/main/kotlin/ContentServer.kt` (default package; main
class `ContentServerKt`), which simply hands control to `ReadingBatServer.start(...)` from
`readingbat-core`.

## Layout

```
src/main/kotlin/Content.kt          # top-level content composition
src/main/kotlin/ContentServer.kt    # main() entry point
src/main/resources/application.conf # Ktor/HOCON config
src/main/resources/logback.xml      # logging config
src/test/kotlin/com/readingbat/     # Kotest tests (com.readingbat package)
jmx/                                # JMX Prometheus agent + config
machines/                           # production machine configs
secrets/                            # deploy scripts (gitignored content)
docs/release_notes.md               # deployment runbook (NOT per-version notes)
RELEASE_NOTES.md                    # per-version highlights
CHANGELOG.md                        # full version history
```

## Build, run, test

All version numbers live in `gradle/libs.versions.toml` — including `jvm` and `gradle`
itself. Treat that file as the single source of truth; do not pin versions in
`build.gradle.kts`.

```bash
./gradlew build -x test     # build without tests
./gradlew check             # run tests + verification
./gradlew run               # run the app
./gradlew buildFatJar       # produce build/libs/server.jar
./gradlew lintKotlin detekt # lint
./gradlew formatKotlin      # apply formatting
./gradlew dependencyUpdates # check for newer deps
./gradlew wrapper --gradle-version=$(grep '^gradle = ' gradle/libs.versions.toml | cut -d'"' -f2) --distribution-type=bin
```

`make help` lists Makefile shortcuts for the above (plus Docker/release flow).

The build uses the Gradle configuration cache (`org.gradle.configuration-cache=true`).
The release-date `BuildConfig` field is sourced from a `ValueSource` so it is
re-evaluated each build instead of being frozen by the cache — keep that pattern
when adding any build-time-dynamic config.

## Tests

Use [Kotest](https://kotest.io) `StringSpec` with an `init {}` block (matches the user's
global preference). Tests live under `src/test/kotlin/com/readingbat/`. The shared
test helpers come from `com.readingbat:readingbat-kotest`. Use MockK where mocking is
needed.

## Lint and formatting

- `kotlinter` (ktlint) for formatting, with project-specific rule disables in `.editorconfig`
- `detekt` for static analysis
- `.editorconfig` sets 2-space indent for Kotlin and tab indent for `Makefile`
- Keep both indent style and the disabled ktlint rules in sync if you add new file types

## Versioning and releases

- Version lives in `gradle.properties` (`version=...`)
- Bump version → update `CHANGELOG.md` `[Unreleased]` → add a `RELEASE_NOTES.md` entry
- GitHub release: tag without `v` prefix (e.g. `3.2.6`), title with `v` prefix (e.g. `v3.2.6`) — see global instructions
- `docker-compose.yml` pins specific image tags; update those alongside any version bump that ships a new image

## Docker / deploy

- `Dockerfile` uses `eclipse-temurin:21-jdk-alpine`, runs as non-root `readingbat` user, exposes 8080/8081/8083/8091-8093, and has a `HEALTHCHECK` on `/ping`
- `make release` builds and pushes multi-arch images (`linux/amd64,linux/arm64`) to `pambrose/readingbat:{latest,$VERSION}`
- Deploy target is Digital Ocean Apps; runbook is in `docs/release_notes.md`
- `make deploy` runs `./secrets/deploy-app.sh`

## Things to remember

- `readingbat-core` is the framework — site changes that look like framework work probably belong upstream
- The `gradle` entry in `libs.versions.toml` is currently informational only; `gradle/wrapper/gradle-wrapper.properties` is what the wrapper actually uses. Keep them in sync when bumping (`make upgrade-wrapper` does this)
- The `LICENSE*` exclude in `shadowJar` is broad — be aware if you ship a dep that requires attribution at the jar root
- `BuildConfig` is generated under `com.readingbat.site`; the `main` function is in the default package (legacy; intentional)
