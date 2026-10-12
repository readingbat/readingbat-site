## Notes on deploying a new version of the ReadingBat Server

Merge the version bump (version, image-tag pins, `CHANGELOG.md`, `RELEASE_NOTES.md`; see
"Releasing and deploying" in the README) to `master` and let CI pass on it. To see what
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
is already on Docker Hub.

Log in to [Digital Ocean](https://digitalocean.com) and click
on the `readingbat` App. Click on `Actions` and then `Deploy`.
