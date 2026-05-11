# Release Notes

Per-version highlights for `readingbat-site`. For the complete change log, see
[`CHANGELOG.md`](CHANGELOG.md). For the *deployment runbook* (how to push a
release to Digital Ocean), see [`docs/release_notes.md`](docs/release_notes.md).

---

## v3.2.6 — Unreleased

Tooling and build hygiene.

- Adopt `detekt` + `kotlinter` with a shared `.editorconfig` so editors and CI
  agree on formatting.
- Make the build safe under Gradle's configuration cache by switching the
  release-date field to a `ValueSource`.
- Centralize `gradle` and `jvm` versions in `libs.versions.toml`; modernize the
  `Makefile` with a self-documenting `help` target and portable fallbacks.

## v3.2.5 — 2026-05-04

Container hardening.

- Dockerfile now declares a `HEALTHCHECK` against `/ping` so orchestrators can
  detect a wedged container without an external probe.
- `COPY` instructions chown into the non-root runtime user so file ownership
  matches the user the JVM runs as.
- Bumped `readingbat-core` to 3.1.8.

## v3.2.4 — 2026-05-04

Routine `readingbat-core` refresh to 3.1.7.

## v3.2.3 — 2026-05-03

Build and Docker cleanups.

- Tightened the Docker build context to reduce image churn.
- Refactored `build.gradle.kts` and fixed broken content-repo URLs.
- Bumped `readingbat-core` to 3.1.6.

## v3.2.2 — 2026-04-25

Dependency refresh: `readingbat-core` 3.1.4, Ktor 3.4.3, Kotlin 2.3.21. Multi-arch
Docker platforms adjusted in the `Makefile`.

## v3.2.1 — 2026-04-12

Bumped `readingbat-core` to 3.1.3.

## v3.2.0 — 2026-04-04

Package migration.

- Code moved under the `com.readingbat` namespace.
- Gradle wrapper updated to 9.5.0; `versions` plugin to 0.54.0.
- Added a conditional `mavenLocal` repository for local development against
  unreleased `readingbat-core` builds.

## v3.1.5 — 2026-03-28

Bumped `readingbat-core` to 3.0.10.

## v3.1.4 — 2026-03-26

Switched the Docker base image to `eclipse-temurin:21-jdk-alpine` for a smaller
image footprint. Assorted dependency updates.

## v3.1.3 — 2026-03-21

`readingbat-core` 3.0.5 plus dead-code cleanup from review.

## v3.1.2 — 2026-03-19

Java 21 runtime.

- Upgraded the JVM toolchain and base image to Java 21.
- Modernized the Dockerfile.
- Upgraded the JMX Prometheus Java agent from 0.14.0 to 1.5.0.

## v3.1.1 — 2026-03-18

Routine dependency and config refresh.

## v3.1.0 — 2026-03-13

- Added a `deploy` Makefile target.
- Upgraded `readingbat-core` to 3.0.1.

## v3.0.0 — 2026-03-12

Major bump alongside `readingbat-core` 3.0.0; Gradle 9.4.0.

---

For older releases (2.x and 1.x), see [`CHANGELOG.md`](CHANGELOG.md).
