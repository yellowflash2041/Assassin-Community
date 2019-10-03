---
title: Committing
---

# Committing and pre-commit hooks

## Style guide

This project follows [thoughtbot's Ruby Style Guide](https://github.com/thoughtbot/guides/blob/master/style/ruby/.rubocop.yml), using [Rubocop](https://github.com/bbatsov/rubocop) along with [Rubocop-Rspec](https://github.com/backus/rubocop-rspec) as the code analyzer. If you have Rubocop installed with your text editor of choice, you should be up and running.

For Javascript, we follow [Airbnb's JS Style Guide](https://github.com/airbnb/javascript), using [ESLint](https://eslint.org) and [prettier](https://github.com/prettier/prettier). If you have ESLint installed with your text editor of choice, you should be up and running.

## Husky hooks

When commits are made, a git precommit hook runs via [husky](https://github.com/typicode/husky) and [lint-staged](https://github.com/okonet/lint-staged). ESLint, prettier, and Rubocop will run on your code before it's committed. If there are linting errors that can't be automatically fixed, the commit will not happen. You will need to fix the issue manually then attempt to commit again.

Note: if you've already installed the [husky](https://github.com/typicode/husky) package at least once (used for precommit npm script), you will need to run `yarn --force` or `npm install --no-cache`. For some reason, the post-install script of husky does not run when the package is pulled from yarn or npm's cache. This is not husky specific, but rather a cached package issue.
