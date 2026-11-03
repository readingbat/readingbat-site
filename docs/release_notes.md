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

Then deploy it:

```bash
make deploy
```

It checks that `:latest` on Docker Hub is this checkout's version (`make docker-verify`), then
runs `doctl apps create-deployment --force-rebuild --wait` on the `readingbat` app, which pulls
`:latest` again and waits for the deployment to go live. It needs
[`doctl`](https://docs.digitalocean.com/reference/doctl/), installed and authenticated
(`doctl auth init`). If the deployment fails, so does `make deploy`. By then Digital Ocean has
rolled back to the deployment that was running.

### A release that changes the app's settings

Some releases need a setting changed along with the image, such as 3.6.0's `DBMS_URL`
(see `RELEASE_NOTES.md`). Push the image, change the setting in the app (`Settings`, the
`pambrose-readingbat` component, `Environment Variables`), then run `make deploy`.

Saving a setting starts a deployment of its own, but that deployment reuses the image the app
already has instead of pulling `:latest`. So it runs the old image with the new setting, and
when the two don't fit, it fails and Digital Ocean rolls back to the deployment that was
running. The site stays up on the old release. The saved setting stays as well, so until
`make deploy` pulls the new image, every deployment that reuses the old one fails the same way.

Change `secrets/docker_env_vars` at the same time: `machines/content/run.sh` and
`docker-compose.yml` read their settings from a copy of it.
