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
`build.gradle.kts`. The one exception is the foojay toolchain resolver in
`settings.gradle.kts`: a settings `plugins {}` block can't read the catalog, and `make versions`
doesn't check settings plugins, so look at its Gradle Plugin Portal page on each dependency
refresh.

`make help` lists the Makefile shortcuts for the build, lint, Docker, and release flow.

The build uses the Gradle configuration cache (`org.gradle.configuration-cache=true`).
Anything build-time-dynamic (a date, a git hash) has to come from a `ValueSource` or another
provider, or the cache freezes the first value it sees. Add one only if something reads it: a
value that changes every build reruns every task downstream of it and misses the build cache.

## CI

Keep new verification tasks wired into `check` — CI runs a single `./gradlew build`, so
anything attached to `check` is picked up without a workflow edit.

The workflow pins every action to a commit SHA with a trailing `# vX.Y.Z` comment, which Dependabot
bumps. Keep the job named `build`: `make release-check` requires a passing check run by that name
(`REQUIRED_CHECKS` in the `Makefile`). `zizmor .github` audits the workflow and Dependabot config.

## Tests

The shared test helpers come from `com.readingbat:readingbat-kotest`.

## Lint and formatting

Keep both the indent style and the disabled ktlint rules in `.editorconfig` in sync if you
add new file types.

`.gitattributes` enforces on the git side what `.editorconfig`'s `end_of_line = lf` only
asks of editors — it matters because CRLF would break `gradlew` and `machines/**/*.sh` on
Linux and in Docker. `*.bat` is the sole CRLF exception; keep the two files in sync.

## Versioning and releases

- Bump version → update `CHANGELOG.md` `[Unreleased]` → add a `RELEASE_NOTES.md` entry
- `docker-compose.yml` and `machines/content/run.sh` pin specific image tags; update those alongside any version bump that ships a new image. `RELEASE_VERSION_FILES` in the `Makefile` is the list `make release-check` enforces — add any new pinning file there
- `settings.gradle.kts` resolves `com.readingbat` from the local Maven repo after Maven Central, so the site can use a `readingbat-core` version that is never published to Central (`make publish-local` in readingbat-core). Such a version must be a readingbat-core tag. CI's "Find the readingbat-core version" step builds it from the tag into the runner's local repo, and `make release-check` refuses a version that is neither on Central nor tagged, or missing from `~/.m2`. The image is built from your `~/.m2` copy, so publish it from the tag, not from a working tree with other changes. `make release-check` still refuses `SNAPSHOT` versions in `libs.versions.toml`
- `docker-push` overwrites `:latest`, so it runs the release gate's checks on what goes into the image: `_check-checkout` (clean tree, no gitignored files under `PACKAGED_PATHS`, on `RELEASE_BRANCH`, no `SNAPSHOT`) and `_check-core`. It skips the Docker Hub check, so it can finish a release that stopped partway through the push. If the Dockerfile starts copying from a new path, add it to `PACKAGED_PATHS`
- `README.md`'s "Project conventions" section summarizes what *this* file covers — if you add or drop a section here, check that summary still matches
- Not every `CHANGELOG.md` version has a compare link. The pre-3.1.1 history and a few 3.1.x
  entries were never tagged, so the link list deliberately skips them and compares against the
  nearest tag that *does* exist — don't "restore" links to tags that aren't in `git tag`
- The README badges hard-code the Ktor and Gradle minor versions; refresh them when
  `libs.versions.toml` moves

## Docker / deploy

Deploy target is Digital Ocean Apps (Docker only — no Heroku); the runbook is in
`docs/release_notes.md`.

- The Dockerfile's `FROM` is pinned by digest; Dependabot (`.github/dependabot.yml`) proposes the bumps. Refresh it by hand (`docker buildx imagetools inspect eclipse-temurin:25-jdk-alpine`, the index `Digest:`) if those stall. On each bump, rerun `docker scout cves` on the base image: once it ships libexpat ≥ 2.10.0 the Dockerfile's `apk upgrade libexpat` is a no-op and can go
- Scan the *built* image (`make docker-scan`), not just the base: `server.jar` hides library CVEs a base-image scan never sees, shaded copies included. Until 3.6.0, `pgjdbc-ng-all` (from readingbat-core) shaded a Netty 4.1.63 with a critical CVE, and its `pom.properties` won the `shadowJar` duplicate, so scanners reported that Netty and missed the 4.2.x the app really uses
- `DBMS_URL` must match the driver the image's readingbat-core uses: `jdbc:postgresql://…?sslmode=require` from 3.6.0 on, `jdbc:pgsql://…?ssl.mode=Require` before it. Each refuses the other's form at startup, so a change of form ships with the image (runbook in `docs/release_notes.md`)
- The JMX exporter agent is a jar vendored in `jmx/` and named in the `ENTRYPOINT`; `make versions` can't see it, so check its GitHub releases on each dependency refresh and update both
- Application files in the image are root-owned on purpose; only `/app/dumps` is writable by the runtime user. Don't reintroduce `COPY --chown`
- The image exits on OOM after dumping, so anything that runs it needs a restart policy (`run.sh` uses `--restart=unless-stopped`, which Docker refuses alongside `--rm`)

## Things to remember

- `docs/release_notes.md` is the deployment runbook, **not** per-version notes (those live in `RELEASE_NOTES.md`)
- `readingbat-core` is the framework — site changes that look like framework work probably belong upstream
- The Kotlin scripting runtime challenges run on (`kotlin-scripting-*`, `kotlin-compiler-embeddable` and friends) is held at 2.4.10, behind the `kotlin` this project builds with, because Kotlin 2.4.20+ keeps every JSR-223 script state's compiler environment reachable. `readingbat-core` owns that hold: it publishes a `strictly` pin, and the rest of the scripting jars follow it. Don't add a site-side resolution rule for it — `eachDependency { useVersion(...) }` overrides `strictly`, so it would silently keep the site behind when core moves its pin. When a `readingbat-core` bump moves the pin, check the heap stays flat while the server loads Kotlin challenges
- The `gradle-wrapper` entry in `libs.versions.toml` is currently informational only; `gradle/wrapper/gradle-wrapper.properties` is what the wrapper actually uses. Keep them in sync when bumping (`make upgrade-wrapper` does this)
- `shadowJar` relies on `DuplicatesStrategy.EXCLUDE` to resolve duplicate license/metadata collisions; it no longer wildcard-excludes `LICENSE*`, so third-party attribution files are preserved in `server.jar`. `META-INF/services/*` files are still merged across jars (the Ktor plugin's fat-jar setup calls `mergeServiceFiles()`), so don't hand-maintain one in `src/main/resources`. The jar-signature excludes are a single vararg `exclude("META-INF/*.SF", "META-INF/*.DSA", "META-INF/*.RSA")` — add new patterns to that call rather than stacking separate `exclude` lines
- `BuildConfig` is generated under `com.readingbat.site`; the `main` function is in the default package (legacy; intentional)
- `build.gradle.kts` groups plugin/extension setup into `Project.configure*` helpers; keep new configuration in that shape rather than adding loose top-level blocks
- The Kotlin unused-return-value checker (`-Xreturn-value-checker=check`) is applied to `compileKotlin` (main) only. Do not extend it to the test source set — Kotest's assertion DSL returns its receiver, so checking tests emits only false positives
