## Notes on deploying a new version of the ReadingBat Server

Create and push a new docker image with:

```bash
make release
```

Log in to [Digital Ocean](https://digitalocean.com) and click
on the `readingbat` App. Click on `Actions` and then `Deploy`.