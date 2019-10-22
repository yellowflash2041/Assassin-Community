---
title: Starting the Application
---

# Starting the application

We're a Rails app, and we use [Webpacker][webpacker] to manage some of
our JavaScript.

Start the application, Webpack, and our job runner [delayed_job][delayed_job]
by running:

```shell
bin/startup
```

(This just runs `foreman start -f Procfile.dev`)

Then point your browser to http://localhost:3000/ to view the site.

If you're working on DEV regularly, you can use `alias start="bin/startup"` to
make this even easier. 😊

If you're using **`pry`** for debugging in Rails, note that using `foreman`
and `pry` together works, but it's not as clean as `bin/rails server`.

Here are some singleton commands you may need, usually in a separate
instance/tab of your shell.

- Running the job server (if using `bin/rails server`) -- this is mostly for
  notifications and emails: **`bin/rails jobs:work`**
- Clearing jobs (in case you don't want to wait for the backlog of jobs):
  **`bin/rails jobs:clear`**

Current gotchas: potential environment issues with external services need to be
worked out.

[delayed_job]: https://github.com/collectiveidea/delayed_job_active_record
[webpacker]: https://github.com/rails/webpacker
