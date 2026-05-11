# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `.editorconfig` to standardize formatting across editors and CI
- `detekt` and `kotlinter` plugins wired in via the version catalog
- Self-documenting `make help` target and `make lint` / `make format` / `make detekt` shortcuts

### Changed
- Build release-date field now sourced from a `ValueSource` so it stays correct under the Gradle configuration cache
- `BuildConfig` package aligned with the rest of the codebase as `com.readingbat.site`
- `Makefile` modernized: guarded version extraction, `.PHONY` consolidated, portable `say` fallback
- `ContentTests` moved into the `com.readingbat` package; copyright headers tidied
- `gradle` and `jvm` versions centralized in `libs.versions.toml`

## [3.2.5] — 2026-05-04

### Added
- Dockerfile `HEALTHCHECK` against `/ping`
- `--chown` on `COPY` instructions so the runtime user owns its files

### Changed
- Bumped `readingbat-core` to 3.1.8

## [3.2.4] — 2026-05-04

### Changed
- Bumped `readingbat-core` to 3.1.7

## [3.2.3] — 2026-05-03

### Changed
- Bumped `readingbat-core` to 3.1.6
- Reformatted `build.gradle.kts`
- Tightened Docker build context and cleaned up the Dockerfile
- Refactored build config and fixed content-repo URLs

## [3.2.2] — 2026-04-25

### Changed
- Updated dependencies: `readingbat-core` 3.1.4, Ktor 3.4.3, Kotlin 2.3.21
- Streamlined build configuration
- Adjusted supported Docker platforms in the Makefile

## [3.2.1] — 2026-04-12

### Changed
- Bumped `readingbat-core` to 3.1.3 (via 3.1.2)

## [3.2.0] — 2026-04-04

### Changed
- Migrated to the `com.readingbat` package namespace
- Bumped Gradle wrapper to 9.5.0, `versions` plugin to 0.54.0
- Cleaned up repository declarations; added a conditional `mavenLocal` for development

## [3.1.5] — 2026-03-28

### Changed
- Bumped `readingbat-core` to 3.0.10 (via 3.0.8)

## [3.1.4] — 2026-03-26

### Changed
- Switched the Docker base image to `eclipse-temurin:21-jdk-alpine`
- Updated assorted dependencies

## [3.1.3] — 2026-03-21

### Changed
- Bumped `readingbat-core` to 3.0.5

### Removed
- Dead code and stale config flagged by code review

## [3.1.2] — 2026-03-19

### Changed
- Upgraded the runtime to Java 21
- Modernized the Dockerfile and bumped dependencies
- Upgraded the JMX Prometheus Java agent from 0.14.0 to 1.5.0

## [3.1.1] — 2026-03-18

### Changed
- Bumped dependencies and tweaked configuration settings

## [3.1.0] — 2026-03-13

### Added
- `deploy` task in the `Makefile`

### Changed
- Upgraded `readingbat-core` to 3.0.1 and consolidated build configuration

## [3.0.0] — 2026-03-12

### Changed
- Upgraded to Gradle 9.4.0 and `readingbat-core` 3.0.0

## [2.1.0] — 2025-08-13

### Changed
- Upgraded to Gradle 9.0.0
- Replaced the Shadow plugin with the Ktor plugin and adjusted build tasks
- Reorganized `build.gradle.kts` and restored `cacheChangingModules` resolution strategy

## [2.0.3] — 2025-04-14

### Changed
- Dependency refresh

## [2.0.0] — 2024-12-04

### Changed
- Moved to Kotlin 2.1.0 and Ktor 3.0.1
- Converted the build to use `libs.versions.toml`
- Upgraded to Kotlin 2.2.0 over the 2.0.x line

## [1.10.x] — 2022-10 → 2022-11

Maintenance releases (1.10.5 → 1.10.8): dependency refreshes and build cleanups.

## [1.8.0] — 2022-05-25

### Changed
- Cleanup after switching hosting to Digital Ocean Apps; dropped Papertrail from `logback.xml`

## [1.7.0] — 2022-04-13

### Changed
- Upgraded to `readingbat-core` 1.26.0

## [1.5.0] — 2021-12-14

### Added
- Release notes document

## [1.4.0] — 2021-11-17

Routine release.

## [1.3.0] — 2021-08-27

Routine release.

## [1.2.x] — 2021-07-16

### Changed
- Upgraded `readingbat-core` through 1.20.0

## [1.0.x → 1.1.x] — 2020-09 → 2021-06

A long maintenance series covering early production hardening. Notable threads:

- Postgres backend conversion; removal of Redis from websockets
- Multi-server / multi-session support; teacher challenge reconnect logic
- Real-time admin feedback; like/dislike on challenges; admin-prefs split
- Kotlin script pools for answer comparison; cleanup of formatting code
- IP geo-location info, Pingdom + Statuspage instrumentation
- Initial Digital Ocean support; addition of JMX/Prometheus agent
- MD5 digests for answer keys; Prometheus + Grafana dashboard links

## [Initial] — 2020-04-23

Project bootstrapped from `readingbat-core`'s site template.

[Unreleased]: https://github.com/readingbat/readingbat-site/compare/3.2.5...HEAD
[3.2.5]: https://github.com/readingbat/readingbat-site/compare/3.2.4...3.2.5
[3.2.4]: https://github.com/readingbat/readingbat-site/compare/3.2.3...3.2.4
[3.2.3]: https://github.com/readingbat/readingbat-site/compare/3.2.2...3.2.3
[3.2.2]: https://github.com/readingbat/readingbat-site/compare/3.2.1...3.2.2
[3.2.1]: https://github.com/readingbat/readingbat-site/compare/3.2.0...3.2.1
[3.2.0]: https://github.com/readingbat/readingbat-site/compare/3.1.5...3.2.0
[3.1.5]: https://github.com/readingbat/readingbat-site/compare/3.1.4...3.1.5
[3.1.4]: https://github.com/readingbat/readingbat-site/compare/3.1.3...3.1.4
[3.1.3]: https://github.com/readingbat/readingbat-site/compare/3.1.2...3.1.3
[3.1.2]: https://github.com/readingbat/readingbat-site/compare/3.1.1...3.1.2
[3.1.1]: https://github.com/readingbat/readingbat-site/compare/3.1.0...3.1.1
[3.1.0]: https://github.com/readingbat/readingbat-site/compare/3.0.0...3.1.0
[3.0.0]: https://github.com/readingbat/readingbat-site/compare/2.1.0...3.0.0
[2.1.0]: https://github.com/readingbat/readingbat-site/compare/2.0.3...2.1.0
[2.0.3]: https://github.com/readingbat/readingbat-site/compare/2.0.0...2.0.3
[2.0.0]: https://github.com/readingbat/readingbat-site/releases/tag/2.0.0
