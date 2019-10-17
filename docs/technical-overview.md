---
title: Technical Overview
---

## 🔑 Key App tech/services

For the Dev.to tech stack we use:

- [_Puma_](https://github.com/puma/puma) as the web server
- [_PostgreSQL_](https://www.postgresql.org/) as the primary database
- [_Fastly_](https://www.fastly.com/) for [edge caching](https://dev.to/ben/making-devto-insanely-fast)
- [_Cloudinary_](https://cloudinary.com/) for image manipulation/serving
- [_Airbrake_](https://airbrake.io/) for error monitoring
- [_Timber_](https://timber.io/) for logging
- [_Delayed Job_](https://github.com/collectiveidea/delayed_job) and [_Active Job_](https://guides.rubyonrails.org/active_job_basics.html) for background workers
- [_Algolia_](https://www.algolia.com/) for search
- [_Redcarpet_](https://github.com/vmg/redcarpet) and [_Rouge_](https://github.com/jneen/rouge) to parse Markdown
- [_Carrierwave_](https://github.com/carrierwaveuploader/carrierwave), [_Fog_](https://github.com/fog/fog-aws) and [_AWS S3_](https://aws.amazon.com/s3/) for image upload/storage
- [_InstantClick_](http://instantclick.io/) (a modified version) instead of _Turbolinks_ to accelerate navigation
- [_Heroku_](https://www.heroku.com) for hosting
- [_Heroku scheduler_](https://devcenter.heroku.com/articles/scheduler) for scheduled jobs
- [_Sendgrid_](https://sendgrid.com/) for transactional mailing
- [_Mailchimp_](https://mailchimp.com/) for marketing/outreach emails
- [_Figaro_](https://github.com/laserlemon/figaro) for app configuration
- [_CounterCulture_](https://github.com/magnusvk/counter_culture) to keep track of association counts (counter caches)
- [_Rolify_](https://github.com/RolifyCommunity/rolify) for role management
- [_Pundit_](https://github.com/varvet/pundit) for authorization
- [_Service Workers_](https://developer.mozilla.org/en-US/docs/Web/API/Service_Worker_API/Using_Service_Workers) to proxy traffic
- [Preact](https://preactjs.com/) for some of the frontend. See [the Frontend Guide](/frontend) for more info
- [_Pusher_](https://pusher.com) for realtime communication between the application and users' browsers
- [_GitDocs_](https://gitdocs.netlify.com) for beautiful and SEO-friendly documentation
- [Git](https://git-scm.com/) for version control
- [GitHub](https://github.com/) for hosting the source code and issue tracking

_This list is non-exhaustive. If you see something that belongs here, feel free to add it._
