## Notes on deploying a new version of the ReadingBat Server

Merge the version bump (version, image-tag pins, `CHANGELOG.md`, `RELEASE_NOTES.md`; see
"Releasing and deploying" in the README) to `master` and let CI pass on it. If the
`readingbat-core` version isn't on Maven Central, publish it to `~/.m2` from its tag first
(`make publish-local` in readingbat-core; see the README). To see what
still blocks a release, without pushing anything:

```bash
make release-check
```

Create and push a new docker image with:

```bash
make release
```

It reruns `release-check`, runs the full test suite from a clean build, asks before pushing,
then pushes `pambrose/readingbat:$VERSION` and `:latest` and checks them with
`make docker-verify`. If a run stops partway through the push or the check, finish with
`make docker-push` and `make docker-verify` directly: `release-check` refuses a version that
is already on Docker Hub. `docker-push` still checks the checkout (clean, on `master`, no
`SNAPSHOT`s) and readingbat-core's source before it pushes.

Then roll the deployment with `make deploy`, or log in to
[Digital Ocean](https://digitalocean.com), click on the `readingbat` App, and click on
`Actions` and then `Deploy`. Both start a new deployment of the app.

### A release that changes the app's settings

Some releases need a setting changed along with the image, such as 3.6.0's `DBMS_URL`
(see `RELEASE_NOTES.md`). Push the image first, then change the setting in the app
(`Settings`, the `pambrose-readingbat` component, `Environment Variables`). Saving it starts
the deployment, and that deployment pulls the new `:latest`, so skip `make deploy`. Deploying
before the change runs the new image on the old settings, and changing it before the push runs
the old image on the new settings. If either deployment fails, Digital Ocean rolls back to the
one that was running, but the saved settings stay as they are, so every later deployment fails
the same way until the setting matches the image.

Change `secrets/docker_env_vars` at the same time: `machines/content/run.sh` and
`docker-compose.yml` read their settings from a copy of it.
