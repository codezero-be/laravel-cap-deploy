# Capistrano Deploy Script for Laravel

##### Zero-downtime deployment script for Laravel apps, using [Capistrano](http://capistranorb.com/).

Disclaimer: I'm not a Capistrano guru and not a server admin. I do know enough to get around and the strategy below works for me. If you encounter problems, feel free to create an issue. I will do my best to help you out, but can't make any promises :)

>   If you want to learn more about servers or zero-downtime deployments, be sure to check out [ServersForHackers.com](https://serversforhackers.com).

## Requirements

- [Ruby](https://www.ruby-lang.org) 2.0 or newer (should be pre-installed on a Mac)
- A server to deploy to
- Some knowledge about servers and SSH

## Installation

The script is based on version 3.4.0 of Capistrano. It might not work on older or newer versions that have breaking changes.

```
gem install capistrano -v 3.4.0
gem install capistrano-composer
```

You might need to use `sudo` if you get a permission error.

## Server Access

Your deploy user will need access to the webserver. Capistrano will use your Mac's `~/.ssh/config` file and use your SSH keys. Check out [these free tutorials](https://serversforhackers.com/series/ssh-usage-tips-and-tricks) to learn how to create and use an SSH key to login to a server. You should end up with something like this in your `~/.ssh/config` file:

```
Host your-server.com
  HostName your-server.com
  Port 22
  User forge
  IdentitiesOnly yes
  IdentityFile ~/.ssh/id_rsa
```

If you are using [Laravel Forge](https://forge.laravel.com/), your deploy user will likely be `forge` and the SSH port `22`.

Make sure you can connect by running `ssh your-server.com` in the terminal.

>   Don't forget you need to store the public key on the server. See the [tutorials](https://serversforhackers.com/series/ssh-usage-tips-and-tricks) for more info.

## Server Preparation

#### Point your website to the correct directory

Configure your webserver so your website's `public` folder is within a `current` folder, for example:

```
/home/forge/your-website.com/current/public
```

#### Allow the deploy user to reload PHP without password

To reload PHP after a deployment, we need to allow the deploy user to do this without the need to enter the sudo password. To achieve this, SSH into your server and run:

```
sudo visudo
```

You will be prompted for the sudo password.

Next, search the text for:

```
# User privilege specification
root    ALL=(ALL:ALL) ALL
```

And add this below it: (make sure the username and reload command is valid for your server)

```
forge  ALL=(ALL:ALL) NOPASSWD:/usr/sbin/service php7.1-fpm reload
```

>   If you want to know a bit more about these user privileges, refer to [this post on ServersForHackers.com](https://serversforhackers.com/video/sudo-and-sudoers-configuration).

## Deployment Settings

Copy the `Capfile` and `deploy` folder from this repo into the root folder of your Laravel app.

In the `deploy/stages` folder, you will find 2 example files: `production.rb` and `staging.rb`. Each represents a server to deploy your app to and holds specific deployment settings for that server.

Running `cap production deploy` would use the `production.rb` settings, and `cap staging deploy` would use the `staging.rb` settings. Just update `your-server`, `your-website` and `your-account` to your needs.

```ruby
server 'your-server.com', roles: %w{web}

set :application, 'your-website.com'
set :repo_url, 'git@github.com:your-account/your-website.git'
set :deploy_to, '/home/forge/your-website.com'
set :keep_releases, 3

set :laravel_artisan_flags, '--env=production'
set :reload_command, 'sudo service php7.1-fpm reload'
```

Also make sure the PHP reload command is valid for your server.

## Before Your First Deploy

First, add a `.env` file to your website's `current` folder on the server, already containing the required passwords. If important passwords are missing (like the database password), deployment will fail, because the database migration step will fail.

Next, on your local machine, `cd` into the root folder of your project and run (for production):

```
cap production deploy:setup
```

**You need to do this once for every new website you set up.**

This will create a `releases` and `shared` folder, move your `.env` file into the `shared` folder and turn the `current` folder into a symlink to the latest `release` folder. Something like this (and a few more):

```
~/your-website.com/current -> ./releases/1234/
~/your-website.com/releases/1234/
~/your-website.com/shared/.env
~/your-website.com/shared/storage/
```

Everything in the `shared` folder will exist throughout deployments.

## Deploy

To deploy your latest code to the server, push it up to GitHub or BitBucket and run:

```
cap production deploy
```

You will be asked what branch you wish to deploy, just press `enter` to accept the default (`master`).

This will now:

-   connect to your server
-   fetch the latest changes from your (online!) git repo
-   create a release folder
-   run a production version of `composer install`, without the dev stuff
-   run `php artisan optimize`
-   migrate the database
-   update the current symlink to the new release folder
-   reload PHP-FPM
-   clear the cache
-   recache the routes and config
-   restart the queue daemon (if any)

## Rollback

To rollback to the previous release, run:

```
cap production deploy:rollback
```

This will not rollback the database, as this might not be needed.

If you do want to rollback the database, run:

```
cap production db:rollback
```

Just be careful with that, especially in production :)

## Other Commands

##### Clear the cache

```
cap production cache:clear
```

##### Cache routes and config

```
cap production cache:routes
cap production cache:config
```

##### Refresh the cache

```
cap production cache:refresh
```

##### Restart the queue daemon

```
cap production queue:restart
```

##### Reload PHP

```
cap production server:reload
```

##### Database

```
cap production db:migrate
cap production db:rollback
cap production db:refresh
cap production db:reset
cap production db:seed
```

##### Maintenance mode

```
cap production deploy:down
cap production deploy:up
```

## License
The MIT License (MIT). Please see [License File](LICENSE.md) for more information.

---
[![Analytics](https://ga-beacon.appspot.com/UA-58876018-1/codezero-be/laravel-cap-deploy)](https://github.com/igrigorik/ga-beacon)
