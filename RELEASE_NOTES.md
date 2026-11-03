# Release Notes

Per-version highlights for `readingbat-site`. For the complete change log, see
[`CHANGELOG.md`](CHANGELOG.md). For the *deployment runbook* (how to push a
release to Digital Ocean), see [`docs/release_notes.md`](docs/release_notes.md).

---

## v3.6.0 — 2026-11-02

A security release. `readingbat-core` 3.6.0 replaces the pgjdbc-ng database
driver, whose final release bundles a Netty with a critical CVE and no fix
coming, with the PostgreSQL JDBC driver.

**Upgrade step required.** Change `DBMS_URL` in the Digital Ocean app and in
`secrets/docker_env_vars`, keeping the host, port, and database:

```
jdbc:pgsql://<host>:<port>/readingbat?ssl.mode=Require        # before
jdbc:postgresql://<host>:<port>/readingbat?sslmode=require    # after
```

3.6.0 stops at startup on the old form, and 3.5.x on the new one. Push the
image, save the new URL in the app, then run `make deploy`. The deployment that
saving the URL starts reuses the 3.5.x image, so it fails and is rolled back;
`make deploy` pulls 3.6.0 (`docs/release_notes.md`). Leave
`DBMS_DRIVER_CLASSNAME` unset.

- The image no longer ships pgjdbc-ng's Netty 4.1.63, which the server's TLS
  connection to the database ran through. Docker Scout's count for the image
  drops from 19 CVEs (one critical, seven high) to 4, none critical or high.
- Bumped the pinned image tags in `docker-compose.yml` and
  `machines/content/run.sh` to 3.6.0.

## v3.5.1 — 2026-11-02

A `readingbat-core` update that stops logging anonymous traffic, Docker image
hardening, a dependency refresh, and build cleanup.

- Bumped `readingbat-core` to 3.5.1, which records only logged-in users'
  requests. Crawlers and bots that keep the session cookie no longer fill
  `server_requests` and `browser_sessions`, anonymous visitors no longer cost
  an ipgeolocation.io lookup, and active-session counts (admin pages and
  Prometheus metrics) now cover logged-in sessions only. It also publishes a
  strict 2.4.10 pin on the Kotlin scripting runtime, so this project drops its
  own copy of that hold; the scripting jars resolve exactly as before.
- Bumped Ktor to 3.6.1, Kotest to 6.2.6, and the Gradle versions plugin to
  0.67.0; upgraded the Gradle wrapper to 9.8.2.
- The image now exits on an `OutOfMemoryError`, after writing the heap dump,
  so the restart policy replaces the damaged JVM; `machines/content/run.sh`
  gains `--restart=unless-stopped` (in place of `--rm`) to match. Retrieve a
  dump by *moving* it off the volume: the JVM never overwrites an existing
  `java_pid1.hprof`, so one left behind means the next OOM writes none.
- The runtime user can write only to `/app/dumps`; the jar, `Content.kt`, and
  config are root-owned and read-only to the server.
- The image upgrades `libexpat` and drops `binutils`, clearing the seven
  high-severity CVEs Docker Scout reports for the base image.
- The base image is pinned by digest, with Dependabot proposing weekly digest
  bumps; the vendored JMX exporter agent moves from 1.5.0 to 1.7.0; the
  `HEALTHCHECK` follows `$PORT`; unused ports 8091 and 8092 are no longer
  exposed.
- Build cleanup: dropped two unused dependencies, two unused `BuildConfig`
  fields (one of which forced a recompile every day), and a hand-written
  script-engine service file the fat jar already merges.
- CI pins its actions to commit SHAs, updated to their current releases, and
  Dependabot now keeps them current.
- `make docker-push` checks the checkout before it replaces `:latest`, and
  the release checks catch gitignored files that would otherwise ship in the
  image. New `make docker-build` and `make docker-scan` targets build the
  image locally and scan it with Docker Scout.
- The site can run on a `readingbat-core` release that is tagged but not on
  Maven Central. Publish it to `~/.m2` from the tag (`make publish-local` in
  readingbat-core). CI builds the same tag itself, and `make release-check`
  accepts the version instead of refusing `mavenLocal()`.

## v3.5.0 — 2026-10-12

A guarded release flow, heap dumps on OOM, and a dependency refresh.

- Bumped `readingbat-core` to 3.5.0.
- Held the Kotlin scripting jars that challenges run on at 2.4.10, while the
  project itself builds with Kotlin 2.4.21. From Kotlin 2.4.20 on, every
  JSR-223 script state keeps its compiler environment (about 27 MB) reachable,
  and `readingbat-core` 3.5.0 starts a new state for every Kotlin script it
  evaluates, so the newer jars would grow the heap with each Kotlin challenge.
- Bumped Kotlin to 2.4.21, the BuildConfig plugin to 6.1.2, and the Gradle
  versions plugin to 0.66.0; upgraded the Gradle wrapper to 9.8.1.
- The image now writes a heap dump to `/app/dumps` on `OutOfMemoryError`, and
  `docker-compose.yml` and `machines/content/run.sh` mount a named volume there
  so the dump outlives the container. A dump is a copy of live memory, secrets
  and user data included, so treat the file as a secret.
- `make release` now gates the push: it runs the new `make release-check`
  (which pushes nothing), the full test suite from a clean build, and a `[y/N]`
  confirmation, then checks the published image with the new
  `make docker-verify`. It no longer overwrites an image already on Docker Hub.
- `make versions` lists only what is out of date; `make versions-all` prints
  the plugin's full report.

## v3.4.0 — 2026-09-21

Dependency refresh and line-ending hygiene.

- Bumped `readingbat-core` to 3.4.0.
- Bumped Ktor to 3.6.0, Kotest to 6.2.5, detekt to 2.0.0-alpha.6, kotlinter to
  5.7.0, the BuildConfig plugin to 6.1.1, and the Gradle versions plugin to
  0.64.0; upgraded the Gradle wrapper to 9.7.1.
- Added `.gitattributes` so text files are stored and checked out with LF,
  keeping `gradlew` and `machines/**/*.sh` executable on Linux and in Docker no
  matter how a contributor has `core.autocrlf` set.
- Fixed the changelog compare links that pointed at tags which were never
  created.

## v3.3.3 — 2026-08-01

Dependency refresh and leaner agent guidance.

- Bumped `readingbat-core` to 3.3.1.
- Bumped the Gradle versions plugin to 0.57.0, which relocated its plugin ID
  from `com.github.ben-manes.versions` to `io.github.ben-manes.versions`.
- Trimmed `CLAUDE.md` of guidance derivable from the repo itself — the directory
  layout, the standard `./gradlew` invocations, and the CI/Dockerfile/editorconfig
  restatements — keeping the gotchas, design rationale, and non-standard
  conventions.

## v3.3.2 — 2026-07-26

CI automation and a dependency refresh.

- Added a GitHub Actions workflow that builds, tests, and lints every push and
  pull request on JDK 25 (Temurin).
- Bumped `readingbat-core` to 3.3.0, Kotlin to 2.4.10, Kotest to 6.2.3, and
  kotlinter to 5.6.0.
- Simplified the `shadowJar` signature-file excludes to a single vararg call.

## v3.3.1 — 2026-07-03

Dependency refresh and build-script cleanup.

- Bumped Ktor to 3.5.1, Kotest to 6.2.1, and detekt to 2.0.0-alpha.5; upgraded
  the Gradle wrapper to 9.6.1.
- Reorganized `build.gradle.kts` into focused `Project.configure*` helpers.
- Enabled Kotlin's unused-return-value checker on production code — kept off the
  test sources, where Kotest's fluent assertions would trigger false positives.

## v3.3.0 — 2026-06-15

Java 25 runtime, dependency refresh, and build hygiene.

- Upgraded the JVM toolchain and Docker base image to Java 25
  (`eclipse-temurin:25-jdk-alpine`).
- Bumped `readingbat-core` to 3.2.0, Kotest to 6.2.0, and detekt to
  2.0.0-alpha.4.
- Adopt `detekt` + `kotlinter` with a shared `.editorconfig` so editors and CI
  agree on formatting.
- Make the build safe under Gradle's configuration cache by switching the
  release-date field to a `ValueSource`.
- Centralize `gradle` and `jvm` versions in `libs.versions.toml`; modernize the
  `Makefile` with a self-documenting `help` target and portable fallbacks.
- Remove the legacy Heroku deploy descriptors (`Procfile`, `system.properties`);
  the app deploys via Docker on Digital Ocean Apps.
- Production logs now carry an ISO-8601 timestamp and thread name.

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
