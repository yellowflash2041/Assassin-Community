---
title: Windows
---

# Installing DEV on Windows 10

## Installing prerequisites

_These prerequisites assume you're working on a 64bit Windows 10 operating
system machine._

### Installing WSL

Since DEV's codebase is using the Ruby on Rails framework, we will need to
install Windows Subsystem for Linux. Some dependencies used by the source code
triggered errors when installing on Windows, so using WSL allows you to work on
the software and not having to fix gem incompatibilities.

First, let's enable Windows Subsystem for Linux in your machine. You can do this
by opening `Control Panel`, going to `Programs`, and then clicking
`Turn Windows Features On or Off`. Look for the `Windows Subsystem for Linux`
option and check the box next to it. Windows will ask for a reboot.

![Enable WSL on Windows](/wsl-feature.png 'Enable WSL on Windows')

Once you've got this installed and after rebooting,
[install Ubuntu 18.04 on Windows](https://www.microsoft.com/store/productId/9N9TNGVNDL3Q).

On your first run, the system will ask for username and password. Take note of
both since it will be used for `sudo` commands.

### Installing rbenv

`rbenv` is a version manager for Ruby applications which allows one to guarantee
that the Ruby version in development environment matches production. First,
install Ruby language dependencies before installing `rbenv`:

```shell
sudo apt-get update
sudo apt-get install git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev software-properties-common libffi-dev
```

Now, we install [rbenv](https://github.com/rbenv/rbenv) using the following
commands:

```shell
cd
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
exec $SHELL

git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc
exec $SHELL
```

One can verify `rbenv` installation using the `rbenv-doctor` script with the
following commands:

```shell
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-doctor | bash
```

### Installing nvm

As a pre-requisite to install Rails, Node.js needs to be installed.
[nvm](https://github.com/nvm-sh/nvm) is a Node.js version manager that helps a
developer select a specific Node.js version for development.

To install `nvm`, follow the instructions outlined in the
[official nvm documentation](https://github.com/nvm-sh/nvm#install--update-script).

Be sure to reload the shell with the command `exec $SHELL` after the
installation is complete.

Run the following command to verify that `nvm` is installed:

```shell
command -v nvm
```

If the shell outputs `nvm`, the installation is successful. Installation of the
correct Node.js version will be done in a later part of the installation
process.

### Yarn

The fastest way to install Yarn for WSL would be from Debian package repository.
Configure the repository with the following commands:

```shell
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
```

Since we do not have Node.js installed yet, we will be installing Yarn without
the default Node.js with the following command:

```shell
sudo apt update && sudo apt install --no-install-recommends yarn
```

To verify Yarn's installation, run the command `yarn -v`. It should print
`Yarn requires Node.js 4.0 or higher to be installed.`. This indicates that the
Yarn installation succeeded but Node.js still needs to be installed for it to
work fully. We install Node.js later on in the installation process.

### PostgreSQL

DEV requires PostgreSQL version 11 or higher.

If you don't have PostgreSQL installed on your Windows system, you can do so
right now. WSL is able to connect to a PostgreSQL instance on your Windows
machine.

Download [PostgreSQL for Windows](https://www.postgresql.org/download/windows/)
and install it.

Pay attention to the username and password you setup during installation of
PostgreSQL as you will use this to configure your Rails applications to login to
the database later.

For additional configuration options, check our
[PostgreSQL setup guide](/installation/postgresql).

### ImageMagick

DEV uses [ImageMagick](https://imagemagick.org/) to manipulate images on upload.

Please refer to ImageMagick's
[instructions](https://imagemagick.org/script/download.php) on how to install
it.

### Redis

DEV requires Redis version 4.0 or higher.

We recommend to follow
[this guide](https://redislabs.com/blog/redis-on-windows-10/) to run Redis under
WSL.

### Elasticsearch

DEV requires a version of Elasticsearch between 7.1 and 7.5. Version 7.6 is not
supported. We recommend version 7.5.2.

We recommend following the install guide
[in Elasticsearch's docs](https://www.elastic.co/guide/en/elasticsearch/reference/7.5/zip-windows.html)
for installing on Windows machines.

NOTE: Make sure to download **the OSS version**, `elasticsearch-oss`.

## Installing DEV

1. Fork DEV's repository, eg. <https://github.com/thepracticaldev/dev.to/fork>
1. Clone your forked repository, eg.
   `git clone https://github.com/<your-username>/dev.to.git`
1. Open the cloned dev.to folder in terminal with `cd dev.to`. Next, install
   Ruby with the following commands:

   ```shell
   rbenv install $(cat .ruby-version)
   rbenv global $(cat .ruby-version)
   ruby -v
   ```

1. Install Node.js with the following set of commands:

   ```shell
   nvm install $(cat .nvmrc)
   nvm use $(cat .nvmrc)
   node -v
   yarn -v
   ```

1. Install bundler with `gem install bundler`
1. Set up your environment variables/secrets

   - Take a look at `Envfile`. This file lists all the `ENV` variables we use
     and provides a fake default for any missing keys.
   - If you use a remote computer as dev env, you need to set `APP_DOMAIN`
     variable to the remote computer's domain name.
   - The [backend guide](/backend) will show you how to get free API keys for
     additional services that may be required to run certain parts of the app.
   - For any key that you wish to enter/replace:

     1. Create `config/application.yml` by copying from the provided template
        (ie. with bash:
        `cp config/sample_application.yml config/application.yml`). This is a
        personal file that is ignored in git.
     1. Obtain the development variable and apply the key you wish to
        enter/replace. ie:

     ```shell
     GITHUB_KEY: "SOME_REAL_SECURE_KEY_HERE"
     GITHUB_SECRET: "ANOTHER_REAL_SECURE_KEY_HERE"
     ```

   - If you are missing `ENV` variables on bootup, the
     [envied](https://rubygems.org/gems/envied) gem will alert you with messages
     similar to
     `'error_on_missing_variables!': The following environment variables should be set: A_MISSING_KEY.`.
   - You do not need "real" keys for basic development. Some features require
     certain keys, so you may be able to add them as you go.

1. Run `bin/setup`.

   > The `bin/setup` script is responsible for installing a varienty of
   > dependencies. One can find it inside the `bin` folder by the name of
   > `setup`.
   >
   > - Its first task is to install the `bundler` gem. Next, it will make
   >   `bundler` install all the gems, including `Rails`, located in `Gemfile`
   >   in the root of the repository. It also installs `foreman`.
   > - It then installs JavaScript dependencies using the script in `bin/yarn`
   >   file. These dependencies are located in `package.json` in the root of the
   >   repository.
   > - Next, it uses various Rake files located inside the `lib` folder to setup
   >   ElasticSearch environment, PostgreSQL database creation and updation.
   > - Finally it cleans up all the log files and restarts the Puma server.

### Possible error messages

1. There is a possibility that you might encounter a _statement timeout_ when
   seeding the database for the first time. Please increase the value of
   `statement_timeout` to `9999999` in `config/database.yml`.

2. If the installation process failed with the following error
   `ERROR: Error installing pg`. Please consider installing the following
   package `libpq-dev` :

```bash
sudo apt-get install libpq-dev
```

3. If the command `bin/setup` fails at installing `cld-0.8.0` with the warnings
   `'aclocal-1.10' is missing on your system` and
   `'automake-1.10' is missing on your system`. Please install `automake-1.10`
   using the commands below.

```shell
cd
sudo apt-get update
sudo apt-get install autoconf
wget https://ftp.gnu.org/gnu/automake/automake-1.10.tar.gz
tar xf automake-1.10.tar.gz
cd automake-1.10/
./configure --prefix=/usr/local
make
```

### WSL2 and System test

In WSL2, hostname/IP address are no longer shared between Windows and Linux.
There are currently two work-arounds.

1. Use dockerized selenium, ie docker-selenium. You will need docker for the
   following steps

   1. `docker run -d --name selenium-hub -p 4444:4444 selenium/hub:3.141.59-20200409`
   2. `CH=$(docker run --rm --name=ch --link selenium-hub:hub -v /dev/shm:/dev/shm selenium/node-chrome:3.141.59-20200409)`
   3. Add `SELENIUM_URL: "http://localhost:4444/wd/hub"` to your
      `application.yml`
   4. Run your System test!

2. Port forward with `socats` (more info needed).

> If you encountered any errors that you subsequently resolved, **please
> consider updating this section** with your errors and their solutions.
