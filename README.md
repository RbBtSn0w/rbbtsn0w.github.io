# rbbtsn0w.github.io

## Theme

It's from [Chirpy Starter](https://github.com/cotes2020/chirpy-starter)

## Deploy by Using GitHub Actions

There are a few things to get ready for.

* If you’re on the GitHub Free plan, keep your site repository public.
* If you have committed Gemfile.lock to the repository, and your local machine is not running Linux, go the the root of your site and update the platform list of the lock-file:

```bash
bundle lock --add-platform x86_64-linux
```

