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
