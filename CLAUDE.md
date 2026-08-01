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

## Build, run, test

All version numbers live in `gradle/libs.versions.toml` — including `jvm` and `gradle`
itself. Treat that file as the single source of truth; do not pin versions in
`build.gradle.kts`.

`make help` lists the Makefile shortcuts for the build, lint, Docker, and release flow.

The build uses the Gradle configuration cache (`org.gradle.configuration-cache=true`).
The release-date `BuildConfig` field is sourced from a `ValueSource` so it is
re-evaluated each build instead of being frozen by the cache — keep that pattern
when adding any build-time-dynamic config.

## CI

Keep new verification tasks wired into `check` — CI runs a single `./gradlew build`, so
anything attached to `check` is picked up without a workflow edit.

## Tests

The shared test helpers come from `com.readingbat:readingbat-kotest`.

## Lint and formatting

Keep both the indent style and the disabled ktlint rules in `.editorconfig` in sync if you
add new file types.

## Versioning and releases

- Bump version → update `CHANGELOG.md` `[Unreleased]` → add a `RELEASE_NOTES.md` entry
- `docker-compose.yml` and `machines/content/run.sh` pin specific image tags; update those alongside any version bump that ships a new image
- `README.md`'s "Project conventions" section summarizes what *this* file covers — if you add or drop a section here, check that summary still matches

## Docker / deploy

Deploy target is Digital Ocean Apps (Docker only — no Heroku); the runbook is in
`docs/release_notes.md`.

## Things to remember

- `docs/release_notes.md` is the deployment runbook, **not** per-version notes (those live in `RELEASE_NOTES.md`)
- `readingbat-core` is the framework — site changes that look like framework work probably belong upstream
- The `gradle-wrapper` entry in `libs.versions.toml` is currently informational only; `gradle/wrapper/gradle-wrapper.properties` is what the wrapper actually uses. Keep them in sync when bumping (`make upgrade-wrapper` does this)
- `shadowJar` relies on `DuplicatesStrategy.EXCLUDE` to resolve duplicate license/metadata collisions; it no longer wildcard-excludes `LICENSE*`, so third-party attribution files are preserved in `server.jar`. The jar-signature excludes are a single vararg `exclude("META-INF/*.SF", "META-INF/*.DSA", "META-INF/*.RSA")` — add new patterns to that call rather than stacking separate `exclude` lines
- `BuildConfig` is generated under `com.readingbat.site`; the `main` function is in the default package (legacy; intentional)
- `build.gradle.kts` groups plugin/extension setup into `Project.configure*` helpers; keep new configuration in that shape rather than adding loose top-level blocks
- The Kotlin unused-return-value checker (`-Xreturn-value-checker=check`) is applied to `compileKotlin` (main) only. Do not extend it to the test source set — Kotest's assertion DSL returns its receiver, so checking tests emits only false positives
