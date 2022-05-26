## Notes on deploying a new ReadingBat Server

Login to server with:

```bash
ssh root@content.readingbat.com
```

Build a new distro and upload new image with:

```bash
cd readingbat-site
git pull
make distro docker
```

Go back to root and launch server with:

```bash
docker run --rm -d --env-file=docker_env_vars -p 8080:8080 pambrose/readingbat:1.8.0
```