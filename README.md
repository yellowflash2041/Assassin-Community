<center><h1>The DEV Community 👩‍💻👨‍💻</h1></center>

<p align="center">
  <img
    alt="DEV"
    src="https://thepracticaldev.s3.amazonaws.com/i/d3o5l9yiqfv1z24cn1yp.png"
    height=200px
  />
</p>
<p align="center">
 The Human Layer of the Stack
</p>
<p align="center">
  <a href="https://www.ruby-lang.org/en/">
    <img src="https://img.shields.io/badge/Ruby-v2.5.1-green.svg" alt="ruby version"/>
  </a>
  <a href="http://rubyonrails.org/">
    <img src="https://img.shields.io/badge/Rails-v5.1.6-brightgreen.svg" alt="rails version"/>
  </a>
  <a href="https://app.codeship.com/projects/229274">
    <img src="https://app.codeship.com/projects/6c96c1d0-3db5-0135-649e-1a9b211ca261/status?branch=master" alt="Codeship Status for thepracticaldev/dev.to_private"/>
  </a>
  <a href="https://codeclimate.com/repos/5a9720ab6f8db3029200792a/maintainability">
    <img src="https://api.codeclimate.com/v1/badges/607170a91196c15668e5/maintainability" />
  </a>
  <a href="https://codeclimate.com/repos/5a9720ab6f8db3029200792a/test_coverage">
    <img src="https://api.codeclimate.com/v1/badges/607170a91196c15668e5/test_coverage" />
  </a>
  <a href="https://www.skylight.io/app/applications/K9H5IV3RqKGu">
    <img src="https://badges.skylight.io/status/K9H5IV3RqKGu.svg?token=Ofd-9PTSyus3BqEZZZbM1cWKJ94nHWaPiTphGsWJMAY" />
  </a>
</p>

## Introduction and Contribution Guideline

Welcome to the [dev.to](https://dev.to) codebase. We are so excited to have you. Most importantly, all contributors must abide by the [code of conduct](https://dev.to/code-of-conduct).

With your help, we can build out the DEV Community platform to be more stable and better serve the community. We are a [Ruby on Rails](http://rubyonrails.org/) app. When in doubt, try to do things "The Rails Way", but it is an evolving codebase and we will learn from all new contributions in order to evolve.

### How to contribute

When in doubt, ask! This is a new process and we need to learn from pain points.

**Refactoring** code, e.g. improving the code without modifying the behavior is an area that can probably be done based on intuition and may not require much communication to be merged.

**Fixing bugs** may also not require a lot of communication, but the more the better. Please surround bug fixes with ample tests. Bugs are magnets for other bugs. Write tests near bugs!

**Building features** is the area which will require the most communication and/or negotiation. Every feature is subjective and open for debate. Let's talk about the features!

### Clean code with tests

Even though some of the existing code is poorly written or untested, we must have more scrutiny for code going forward. We test with [rspec](http://rspec.info/), let us know if you have any questions about this!

### The bottom line

We are all humans trying to work together to improve things for the community. Always be kind and appreciate the need for tradeoffs. ❤️

# Getting Started

#### Prerequisite

* Ruby: we recommend using [rbenv](https://github.com/rbenv/rbenv) to install the Ruby version listed on the badge.
* Bundler: `gem install bundler`
* Foreman: `gem install foreman`
* Yarn: use `brew install yarn` to install yarn. It will also install node if you don't already have it.
* PostgresSQL: the easiest way to get started with this is to use [Postgres.app](https://postgresapp.com/).

#### Installation steps

1.  `git clone git@github.com:thepracticaldev/dev.to_core.git`
2.  `bundle install`
3.  `bin/yarn`
4.  Set up your environment variables/secrets
    * Create a `config/application.yml` file to store development secrets. This is a personal file that is ignored in git.
    * Copy [`config/sample_application.yml`](config/sample_application.yml) in order to create a valid `application.yml`
    * You'll need to get your own free API keys for a few services in order to get your development environment running. [**Follow this wiki to get them.**](https://github.com/thepracticaldev/dev.to_core/wiki/Getting-API-Keys-for-Basic-Development)
    * If you are missing `ENV` variables on bootup, `_env_checker.rb` will let you know. If you add or remove `ENV` vars to the project, you must also modify this file before they can be merged. The wiki above should handle all the necessary keys for basic development.
    * You do not need "real" keys for basic development. Some features require certain keys, so you may be able to add them as you go.
5.  Run `bin/setup`

#### Starting the application

We're mostly a Rails app, with a bit of Webpack sprinkled in. **For most cases, simply running `bin/rails server` will do.** If you're working with Webpack though, you'll need to run the following:

* Run **`bin/startup`** to start the server, Webpack, and our job runner `delayed_job`. `bin/startup` runs `foreman start -f Procfile.dev` under the hood.
* `alias start="bin/startup"` makes this even faster. 😊
* If you're using **`pry`** for debugging in Rails, note that using `foreman` and `pry` together works, but it's not as clean as `bin/rails server`.

Here are some singleton commands you may need, usually in a separate instance/tab of your shell.

* Running the job server (if using `bin/rails server`) -- this is for mostly for notifications and emails: **`bin/rails jobs:work`**
* Clearing jobs (in case you don't want to wait for the backlog of jobs): **`bin/rails jobs:clear`**

Current gotchas: potential environment issues with external services need to be worked out.

## ⚛ Front-End Development

There is some legacy code which is old school JS, but for all things new, [Preact](https://preactjs.com) is the where it's at. If you're new to Preact, check out their [documentation](https://preactjs.com/guide/getting-started). Also, consider following the [#preact](https://dev.to/t/preact) tag on [dev.to](https://dev.to).

### 👷‍ Building components

We use [Storybook](https://storybook.js.org) to develop components. It allows you to focus on building components without the burden of the whole application running. If you're new to Storybook, check out their [documentation](https://storybook.js.org/basics/guide-react). Also, consider following the [#storybook](https://dev.to/t/storybook) tag on [dev.to](https://dev.to).

To get Storybook running on your local:

* 📦 Run `npm install` or `yarn` to ensure all your dependencies are installed.
* 🏁 Run `npm run storybook` or `yarn storybook` to start Storybook.
* 🏗️ Start working on your component and see the changes in Storybook as you save.

## 🔑 Key App tech/services

* We use **Puma** for the server
* We [rely heavily on edge caching](https://dev.to/ben/making-devto-insanely-fast) with **Fastly**
* We use **Cloudinary** for image manipulation/serving
* We use **Keen** for event storage
* We use **Airbrake** for error monitoring
* We use **Timber** for logging
* We use **Delayed Job** for background workers
* We use **Algolia** for search
* We use **Redcarpet/Rouge** for Markdown
* We use **Carrierwave/Fog/AWS S3** for image upload/storage
* We use a modified version of **InstantClick** instead of **Turbolinks**
* We are hosted on **Heroku**
* We use **Heroku scheduler** for scheduled jobs (default)
* We use **Sendgrid** for API-triggered mailing
* We use **Mailchimp** for marketing/outreach emails
* We use **Figaro** for app configuration.
* We use **CounterCulture** to keep track of association counts (counter caches)
* We use **Rolify** for role management.
* We use **Pundit** for authorization.
* We use Service Workers to proxy traffic

There's more, but that's a decent overview of the key need-to-knows.

## Workflow Suggestion

We use [Spring](https://github.com/rails/spring) and it is already included in the project.

1.  Use the provided bin stubs to automatically start Spring, i.e. `bin/rails server`, `bin/rspec spec/models/`, `bin/rake db:migrate`.
2.  If Spring isn't picking up on new changes, use `spring stop`. For example, Spring should always be restarted if there's a change in environment key.
3.  Check Spring's status whenever with `spring status`.

Caveat: `bin/rspec` is not equipped with Spring because it affect Simplecov's result. Instead use `bin/spring rspec`.

## Style Guide

This project follows [Bbatsov's Ruby Style Guide](https://github.com/bbatsov/ruby-style-guide), using [Rubocop](https://github.com/bbatsov/rubocop) along with [Rubocop-Rspec](https://github.com/backus/rubocop-rspec) as the code analyzer. If you have Rubocop installed with your text editor of choice, you should be up and running. Settings can be edited in `.rubocop.yml`.

For Javascript, we follow [Airbnb's JS Style Guide](https://github.com/airbnb/javascript), using [ESLint](https://eslint.org) and [prettier](https://github.com/prettier/prettier). If you have ESLint installed with your text editor of choice, you should be up and running.

When commits are made, a git precommit hook runs via [husky](https://github.com/typicode/husky) and [lint-staged](https://github.com/okonet/lint-staged) on front-end code that will run eslint and prettier on your code before committing it. If there are linting errors and eslint isn't able to automatically fix it, the commit will not happen. You will need to fix the issue manually then attempt to commit again.

Note: if you've already installed the [husky](https://github.com/typicode/husky) package at least once (used for precommit npm script), you will need to run `yarn --force` or `npm install --no-cache`. For some reason the post-install script of husky does not run, when the package is pulled from yarn's or npm's cache. This is not husky specific, but rather a cached package specific issue.

## Testing

The following technologies are used for testing:

* **Rspec**
* **Capybara** with **selenium-webdriver**
  * **chromedriver-helper** for standard JS testing.
* **`rack_session_access`**
* **Warden**
* **guard-rspec** for automated testing
* [Jest](https://facebook.github.io/jest) for testing in the front-end.

#### When should I use `login_via_session_as(:user)` vs `login_as(:user)`?

* `login_as(:user)` uses Warden's stubbing actions to make the application think that a user is signed in but without all of the overhead of actually signing them in. Recommended for view test.
* `login_via_session_as(:user)` uses `rack_session_access` to modify application's session. It is integrated with Devise so current_user won't be nil. Recommended for feature test.

## Previewing emails in development

You can modify the test in `/test/mailers/previews`
You can view the previews at (for example) `http://localhost:3000/rails/mailers/notify_mailer/new_reply_email`

## How to contribute (Internal)

1.  Clone the project locally.
2.  Create a branch for each separate piece of work.
3.  Do the work and write [good commit messages](https://chris.beams.io/posts/git-commit/).

* If your work includes adding a new environment variable, make sure you update `_env_checker.rb`.

4.  Push your branch up to this repository.
5.  Create a new pull-reqest.
6.  After the pull-request is approved and merged, delete your branch on github.

**Avoid pushing spike(test) branches up to the main repository**. If you must, push the spike branches up to a forked repository.

<!-- This would be how we would contribute if we are doing a fork-and-branch workflow
1. Fork the project & clone locally.
2. Create an upstream remote and sync your local copy before you branch.
3. Create a branch for each separate piece of work.
4. Do the work and write good commit messages.
5. Push to your origin repository.
6. Create a new PR in GitHub.
-->

### Branch Policies

#### Branch naming convention

Name the branch in the following manner.
`<your-name>/<type>/<github issue# (if there's one)>-<name>`

###### Examples

```text
ben/feature/renderer-cookies
jess/hotfix/dockerfile-base-image
andy-mac/issue/#132-broken-link
```

#### Pull request guideline

* Keep the pull request small; a pull request should try it's very best to address only a single concern.
* Make sure all the tests pass and add additional tests for the code you submit.
* Document your reasoning behind the changes. Explain why you wrote the code in the way you did, not what it does.
* If there's an existing issue related to the pull request, reference to it. [More info here](https://github.com/blog/1506-closing-issues-via-pull-requests)

Please note that we squash all pull request. **After a pull request is approved, we will remove the branch the PR is on unless you state it otherwise**

## Continuous Integration & Continuous Deployment

We are using Codeship for CI and CD. Codeship will run a build (in isolated environment for testing) for every push to this repository. Keep in mind that a passing-build does not necessarily mean the project won't run into any issues. Strive to write good tests for any chunk of code you wish to contribute. Only pushes to the `deployment` branch will evoke the CD portion of Codeship after CI passes. Our test suite is not perfect and sometimes a re-rerun is needed.

#### Skipping CI build (Not recommended)

If your changes are minor (i.e. updating README), you can skip CI by adding `--skip-ci` to your commit message. More info [here](https://documentation.codeship.com/general/projects/skipping-builds/).

## CodeClimate and Simplecov

We are using CodeClimate to track code quality and code coverage. Codeclimate will grade the quality of the code of every PR but not the entirety of the project. If you feel that the current linting rule is unreasonable, feel free to submit a _separate_ PR to change it. Fix any errors that Codeclimate provides and strive to leave code better than you found it.

Simplecov is a gem that is tracking the coverage of our test suite. Codeship will upload Simplecov data to CodeClimate. We are still in the early stage of using it so it may not provide an accurate measurement our of codebase.

#### Using simplecov locally

1.  Run `bundle exec rspec spec` or `bin/rspec spec`. You can run rspec on the whole project or a single file.
2.  After rspec is complete, open `index.html` within the coverage folder to view code coverages.

Run `bin/rspecov` to do all of this in one step
