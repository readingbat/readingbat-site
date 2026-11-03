# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [3.6.1] — 2026-11-03

A drop-in bump from 3.6.0: no settings change, so push the image and run `make deploy`.

### Added
- `make logs`, which follows the Digital Ocean app's runtime log (`doctl apps logs --follow --type
  run`), finding the app by `DO_APP_NAME` as `make deploy` does. It replaces `make do-log` and
  `secrets/app-log.sh`

### Changed
- Bumped `readingbat-core` to 3.6.1. Its Sessions admin page shows each session's login time, in
  place of its last activity, and a single Location column. It drops the Remote Host, ISP, and User
  Agent columns, so a session whose IP or user agent changes is one row with its full request
  count, and it covers the last 7 days by default, up from 2. Resend moves to 4.30.0
- Bumped the pinned image tags in `docker-compose.yml` and `machines/content/run.sh` to 3.6.1
- `make deploy` runs `doctl apps create-deployment --force-rebuild --wait` on the Digital Ocean app
  named `DO_APP_NAME` (`readingbat`), in place of `secrets/deploy-app.sh`. It pulls `:latest` again,
  after `make docker-verify` has checked that `:latest` is this checkout's version, and it fails if
  the deployment does. It needs `doctl`, installed and authenticated

### Fixed
- The deploy runbook said that saving a setting in the Digital Ocean app deploys the new `:latest`,
  so `make deploy` could be skipped. That deployment reuses the image the app already has: saving
  3.6.0's `DBMS_URL` ran the 3.5.1 image, which refused the new URL, and was rolled back. The
  runbook and the 3.6.0 release notes now say to save the setting and then run `make deploy`

## [3.6.0] — 2026-11-02

**Upgrade step required.** `DBMS_URL` moves to the PostgreSQL driver's form, keeping the host, port,
and database: `jdbc:pgsql://host:port/readingbat?ssl.mode=Require` becomes
`jdbc:postgresql://host:port/readingbat?sslmode=require`. Change it in the Digital Ocean app and in
`secrets/docker_env_vars` (for `run.sh` and `docker-compose.yml`) after pushing the image. 3.6.0 stops at
startup on the old form and 3.5.x on the new one (`docs/release_notes.md`). `DBMS_DRIVER_CLASSNAME`
must stay unset, as it is in both, or be `org.postgresql.Driver`.

### Changed
- Bumped `readingbat-core` to 3.6.0, which connects to PostgreSQL with the PostgreSQL JDBC driver
  (`org.postgresql:postgresql` 42.7.14) in place of pgjdbc-ng, and rejects pgjdbc-ng settings at
  startup with a message naming the replacement. Its strict 2.4.10 pin on the Kotlin scripting
  runtime is unchanged
- The commented-out local `dbms` block in `application.conf` uses the `jdbc:postgresql:` form
- Bumped the pinned image tags in `docker-compose.yml` and `machines/content/run.sh` to 3.6.0
- The deploy runbook (`docs/release_notes.md`) covers a release that needs a setting changed along
  with the image: push first, then save the setting, which starts the deployment. A failed
  deployment rolls back, but the saved setting stays, so every later deployment fails too

### Removed
- `com.impossibl.pgjdbc-ng:pgjdbc-ng-all` 0.8.9, which `readingbat-core` no longer brings in

### Security
- The image no longer ships the Netty 4.1.63 that `pgjdbc-ng-all` 0.8.9, its final release, bundles
  under `com.impossibl.shadow.io.netty`. The server's TLS connection to the database ran through it.
  Docker Scout's count for the built image drops from 19 CVEs (one critical, CVE-2026-75595, and
  seven high) to 4, none critical or high: three in Alpine's coreutils with no fix released, and an
  unrated one in musl. Its `pom.properties` also won the duplicate in `server.jar`, so scanners
  reported that Netty and missed the 4.2.x the server uses for HTTP; Scout now reports 4.2.19

## [3.5.1] — 2026-11-02

### Added
- `.github/dependabot.yml`, which proposes weekly bumps of the Dockerfile's base-image digest and of
  the CI workflow's actions, holding each new release back until it is a week old
- `make docker-build`, which builds the image for this machine into the local Docker as
  `readingbat:local`, and `make docker-scan`, which then lists its CVEs with Docker Scout,
  `server.jar`'s libraries included

### Changed
- The image exits on an `OutOfMemoryError` (`-XX:+ExitOnOutOfMemoryError` in `JAVA_TOOL_OPTIONS`),
  after the heap dump is written. It used to keep running a JVM that may have lost a thread to the
  OOM, and a restart policy only replaces a container that exits. `machines/content/run.sh` now runs
  the container with `--restart=unless-stopped` in place of `--rm`, which Docker refuses alongside a
  restart policy, so an OOM there no longer leaves the server down
- The dump-retrieval commands in `machines/content/run.sh` and the README move `java_pid1.hprof` off
  the volume instead of copying it. Every container's JVM is pid 1, and the JVM will not overwrite an
  existing dump, so a dump left on the volume meant the next OOM wrote none
- The application files in the image (`server.jar`, `Content.kt`, the resources, and the JMX agent)
  are owned by root, and the runtime user can write only to `/app/dumps`. They were owned by the
  runtime user, so the server could have modified its own jar and the `Content.kt` it evaluates
- Pinned the base image to its multi-arch digest, so a rebuild of the same version gets the same JDK
- The image upgrades `libexpat` to Alpine's 2.10.0-r0 and removes `binutils`, clearing the base
  image's seven high-severity CVEs (four in libexpat 2.9.0, three unfixed in binutils 2.45.1) per
  Docker Scout. Neither was reachable from the server: only fontconfig uses libexpat, and binutils is
  there for `jlink`. The libexpat upgrade can go once a base-image digest bump carries the fix
- Bumped the vendored Prometheus JMX exporter agent from 1.5.0 to 1.7.0. Being a checked-in jar,
  `make versions` does not report it; the Dockerfile and README now say where to check
- The `HEALTHCHECK` probes `$PORT` when it is set, matching the port override `application.conf`
  honors, instead of always probing 8080
- `EXPOSE` drops ports 8091 and 8092, which nothing listens on, and the `ENTRYPOINT` drops `-server`,
  a no-op on 64-bit JVMs
- Bumped `readingbat-core` to 3.5.1. Request logging now records logged-in users only: a request
  without a login writes nothing to `server_requests` or `browser_sessions`, so crawlers and bots
  that keep the browser-session cookie no longer fill those tables, and a new anonymous visitor no
  longer triggers an ipgeolocation.io lookup. The active-session counts on the admin pages and in
  the Prometheus metrics count logged-in sessions only; existing rows are left alone. The release
  also publishes a strict 2.4.10 pin on its Kotlin scripting runtime, which now holds this
  project's scripting jars by itself (see Removed)
- Bumped Ktor to 3.6.1, Kotest to 6.2.6, and the Gradle versions plugin to 0.67.0
- Upgraded the Gradle wrapper to 9.8.2
- Bumped the pinned image tags in `docker-compose.yml` and `machines/content/run.sh` to 3.5.1
- The site can depend on a `readingbat-core` version that is never published to Maven Central.
  `settings.gradle.kts` resolves `com.readingbat` from the local Maven repo after Central. The
  version must be a readingbat-core tag: when Central lacks it, CI builds it from the tag into the
  runner's local repo before building the site. `make release-check` no longer refuses
  `mavenLocal()`. It refuses a core version that is neither on Central nor tagged, or that is
  missing from `~/.m2`, and notes when the image will take core from `~/.m2`
- `make docker-push` runs the release gate's checks on what goes into the image before it pushes:
  a clean tree on `master`, no `SNAPSHOT` versions, and a `readingbat-core` that is on Maven
  Central or tagged. It used to push, and replace `:latest`, from any checkout
- The release checks also fail on gitignored files under `src/main` or `jmx/`. `git status` doesn't
  list those, but the build and the Dockerfile would package them into the public image
- `make clean-all` no longer runs Gradle, so it works when the build script is broken, and it also
  removes `.kotlin/`. `make build` no longer cleans first. `make tests` reruns only the tests,
  rather than every task. `make cc` drops a `-x test` that did nothing
- The CI workflow pins its actions to commit SHAs and moves them to `actions/checkout` 7.0.1,
  `actions/setup-java` 6.1.0, and `gradle/actions/setup-gradle` 6.4.1. It runs with a read-only
  `GITHUB_TOKEN` and no longer leaves the token in the checkout's git config

### Removed
- This project's own Kotlin scripting hold (`configureScripting` and the `kotlin-scripting` catalog
  entry). `readingbat-core` 3.5.1 publishes the same 2.4.10 pin, so the resolved jars are unchanged.
  The rule's `useVersion` also overrode core's `strictly` pin, so once core moved it the site would
  have stayed behind without a word
- The `SITE_NAME` and `SITE_RELEASE_DATE` `BuildConfig` fields, which nothing read, and the
  `ValueSource` behind the date. The date changed daily, so the first build each day recompiled and
  missed the build cache
- The unused `kotlin-logging` and `kotest-assertions-ktor` dependencies. `readingbat-core` still
  brings in `kotlin-logging`
- The hand-written `META-INF/services/javax.script.ScriptEngineFactory`. Each script engine's jar
  registers itself, and the fat jar merges those registrations

## [3.5.0] — 2026-10-12

### Added
- Heap dumps on `OutOfMemoryError`. The image now sets
  `JAVA_TOOL_OPTIONS=-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/app/dumps`, and both
  `docker-compose.yml` and `machines/content/run.sh` mount a named volume there so a dump outlives the
  container that produced it. Named rather than bind mounts because Docker creates a missing bind-mount
  directory as root while the image runs as uid 1000; one volume per composed service because each
  container is pid 1 and they would otherwise overwrite each other's `java_pid1.hprof`. A dump is the
  only record of what was holding memory at the moment of an OOM. It is also a copy of live memory,
  so it carries secrets and user data — treat the file as a secret
- `make release-check`, which pushes nothing and fails unless the checkout is fit to release
  `VERSION`. It needs a final (non-pre-release) version, a clean tree on `master` matching
  `origin/master`, no `SNAPSHOT` versions in `libs.versions.toml` and no active `mavenLocal()`, a
  `CHANGELOG.md` and a `RELEASE_NOTES.md` section for the version, every image pin in
  `docker-compose.yml` and `machines/content/run.sh` at the version, a `VERSION` tag (if any) on
  HEAD, a passing CI `build` check for HEAD, and no `VERSION` image already on Docker Hub. A
  network check that gets no clear answer fails rather than passing
- `make docker-verify`, which checks that the published `VERSION` image carries every platform
  and that `:latest` has the same digest
- `make versions-all`, the dependency-updates plugin's own plain report, which also lists every
  dependency already up to date

### Changed
- Bumped `readingbat-core` to 3.5.0
- Bumped Kotlin to 2.4.21, the BuildConfig plugin to 6.1.2, and the Gradle versions plugin to 0.66.0
- Held the runtime Kotlin scripting jars (`kotlin-scripting-*`, `kotlin-compiler-embeddable`) at
  2.4.10 through a new `kotlin-scripting` catalog version, while the project itself builds with
  Kotlin 2.4.21. From Kotlin 2.4.20 on, every JSR-223 script state keeps its compiler environment
  (about 27 MB) reachable, and readingbat-core 3.5.0, which brings in the 2.4.21 scripting jars,
  starts a new state for every Kotlin script it evaluates, so the heap grows with each Kotlin
  challenge the server loads
- Upgraded the Gradle wrapper to 9.8.1
- Bumped the pinned image tags in `docker-compose.yml` and `machines/content/run.sh` to 3.5.0
- `make versions` now lists only the dependencies with newer versions (and any that could not be
  checked, and a Gradle update), one line each. `build.gradle.kts` gives `dependencyUpdates` its
  own output formatter; the full report, which opens with every up-to-date dependency, moved to
  `make versions-all`
- `make release` now runs `release-check`, a clean run of the full test suite, and a `[y/N]`
  confirmation before it pushes, then runs `docker-verify`. It used to build and push with no
  tests and no checks, so it would silently overwrite an image that had already been published.
  `docker-push` refuses pre-release versions, since it also tags `:latest`

## [3.4.0] — 2026-09-21

### Added
- `.gitattributes` to normalize line endings in the repository. Text files are stored and checked out with LF so `gradlew`, `machines/**/*.sh`, and the `Dockerfile` stay executable on Linux and in Docker regardless of a contributor's `core.autocrlf`; `*.bat` is checked out with CRLF, and `*.jar` is marked binary

### Changed
- Bumped `readingbat-core` to 3.4.0
- Bumped Ktor to 3.6.0, Kotest to 6.2.5, detekt to 2.0.0-alpha.6, kotlinter to 5.7.0, the BuildConfig plugin to 6.1.1, and the Gradle versions plugin to 0.64.0
- Upgraded the Gradle wrapper to 9.7.1
- Bumped the pinned image tags in `docker-compose.yml` and `machines/content/run.sh` to 3.4.0

### Fixed
- Corrected the changelog compare links: versions that predate the current tagging convention (3.1.5, 3.1.4, 3.1.2, 3.1.0, 3.0.0, and the 1.x/2.x entries) were never tagged, so their links pointed at refs that do not exist. Those links are dropped and the remaining ones compare against the nearest tag that exists

## [3.3.3] — 2026-08-01

### Changed
- Bumped `readingbat-core` to 3.3.1
- Bumped the Gradle versions plugin to 0.57.0, whose plugin ID moved from `com.github.ben-manes.versions` to `io.github.ben-manes.versions`
- Trimmed `CLAUDE.md` of guidance derivable from the repo itself (directory layout, standard Gradle invocations, the CI workflow restatement, and lint/Docker file summaries), keeping the gotchas, design rationale, and non-standard conventions

## [3.3.2] — 2026-07-26

### Added
- GitHub Actions CI workflow (`.github/workflows/ci.yml`) that builds, tests, and lints on JDK 25 (Temurin) for pushes and pull requests

### Changed
- Bumped `readingbat-core` to 3.3.0, Kotlin to 2.4.10, Kotest to 6.2.3, and kotlinter to 5.6.0
- Simplified the `shadowJar` signature-file excludes to a single vararg call
- Bumped the pinned image tags in `docker-compose.yml` and `machines/content/run.sh` to 3.3.2

## [3.3.1] — 2026-07-03

### Added
- Enabled Kotlin's unused-return-value checker (`-Xreturn-value-checker=check`) on the main source set. It is deliberately left off the test source set, where Kotest's assertion DSL returns its receiver and tests discard that result by design.

### Changed
- Reorganized `build.gradle.kts` into focused `Project.configure*` helpers (Kotlin, Detekt, Kotlinter, Ktor, `shadowJar`, `test`, dependency-updates)
- Bumped Ktor to 3.5.1, Kotest to 6.2.1, and detekt to 2.0.0-alpha.5
- Upgraded the Gradle wrapper to 9.6.1

## [3.3.0] — 2026-06-15

### Added
- `.editorconfig` to standardize formatting across editors and CI
- `detekt` and `kotlinter` plugins wired in via the version catalog
- Self-documenting `make help` target and `make lint` / `make format` / `make detekt` shortcuts

### Changed
- Upgraded the JVM toolchain and Docker base image to Java 25 (`eclipse-temurin:25-jdk-alpine`)
- Bumped `readingbat-core` to 3.2.0; adapted `ContentTests` to the now-`suspend` `correctAnswers()` API
- Bumped Kotest to 6.2.0 and detekt to 2.0.0-alpha.4
- Build release-date field now sourced from a `ValueSource` so it stays correct under the Gradle configuration cache
- `BuildConfig` package aligned with the rest of the codebase as `com.readingbat.site`
- `Makefile` modernized: guarded version extraction, `.PHONY` consolidated, portable `say` fallback
- `ContentTests` moved into the `com.readingbat` package; copyright headers tidied
- `gradle` and `jvm` versions centralized in `libs.versions.toml`
- Dropped the redundant explicit `application` Gradle plugin (the Ktor plugin applies it transitively)
- Narrowed the `shadowJar` exclude so third-party `LICENSE`/attribution files are retained in `server.jar`
- Production logging now includes an ISO-8601 timestamp and thread name
- Corrected a `docker-compose.yml` container-port mapping (`8084` → `8081`), bumped the pinned image tags (and `machines/content/run.sh`) to 3.3.0, and synced the `machines/` JMX agent references to 1.5.0

### Removed
- Legacy Heroku deploy descriptors `Procfile` and `system.properties` — the app deploys via Docker on Digital Ocean Apps, and the JVM version now lives solely in `gradle/libs.versions.toml` and the Dockerfile base image

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

---

Versions above without a compare link (3.1.5, 3.1.4, 3.1.2, 3.1.0, 3.0.0, and the 1.x/2.x
entries) predate the current tagging convention and were never tagged in git, so there is no
diff to link to. The entries below skip those versions and compare against the nearest
tag that exists.

[Unreleased]: https://github.com/readingbat/readingbat-site/compare/3.6.1...HEAD
[3.6.1]: https://github.com/readingbat/readingbat-site/compare/3.6.0...3.6.1
[3.6.0]: https://github.com/readingbat/readingbat-site/compare/3.5.1...3.6.0
[3.5.1]: https://github.com/readingbat/readingbat-site/compare/3.5.0...3.5.1
[3.5.0]: https://github.com/readingbat/readingbat-site/compare/3.4.0...3.5.0
[3.4.0]: https://github.com/readingbat/readingbat-site/compare/3.3.3...3.4.0
[3.3.3]: https://github.com/readingbat/readingbat-site/compare/3.3.2...3.3.3
[3.3.2]: https://github.com/readingbat/readingbat-site/compare/3.3.1...3.3.2
[3.3.1]: https://github.com/readingbat/readingbat-site/compare/3.3.0...3.3.1
[3.3.0]: https://github.com/readingbat/readingbat-site/compare/3.2.5...3.3.0
[3.2.5]: https://github.com/readingbat/readingbat-site/compare/3.2.4...3.2.5
[3.2.4]: https://github.com/readingbat/readingbat-site/compare/3.2.3...3.2.4
[3.2.3]: https://github.com/readingbat/readingbat-site/compare/3.2.2...3.2.3
[3.2.2]: https://github.com/readingbat/readingbat-site/compare/3.2.1...3.2.2
[3.2.1]: https://github.com/readingbat/readingbat-site/compare/3.2.0...3.2.1
[3.2.0]: https://github.com/readingbat/readingbat-site/compare/3.1.3...3.2.0
[3.1.3]: https://github.com/readingbat/readingbat-site/compare/3.1.1...3.1.3
[3.1.1]: https://github.com/readingbat/readingbat-site/compare/1.13.0...3.1.1
