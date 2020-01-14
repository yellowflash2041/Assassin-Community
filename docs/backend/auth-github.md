---
title: GitHub Authentication
---

# GitHub App and Authentication

DEV allows you to authenticate using GitHub. To use this authentication method
in local development, you will need to set up a GitHub App and retrieve its
keys. Then you'll need to provide these keys to the Rails application.

1. [Click this link to create a new OAuth application in your Github
   account](https://github.com/settings/applications/new) - you will be
   redirected to sign in to Github account if you have not already.

2. Fill in the form with an application name, description, and the URL
   `http://localhost:3000/`. Replace the port `3000` if you run DEV on another
   port.

   ![github-1](https://user-images.githubusercontent.com/22895284/51085500-877a6c00-173a-11e9-913a-0dccad234cf3.png)

3. You will be redirected to the app's **Developer settings**. Here you will
   find the keys. Change them accordingly (name of GitHub key -> name of our
   `ENV` variable):

   ```text
   Client ID -> GITHUB_KEY
   Client Secret -> GITHUB_SECRET
   ```

   ![github-2](https://user-images.githubusercontent.com/22895284/51085862-49337b80-173f-11e9-8503-f8251d07f458.png)
   
4. Done.
