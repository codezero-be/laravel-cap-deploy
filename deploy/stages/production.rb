server 'your-server.com', roles: %w{web}

set :application, 'your-website.com'
set :repo_url, 'git@github.com:your-account/your-website.git'
set :deploy_to, '/home/forge/your-website.com'
set :keep_releases, 3

set :laravel_artisan_flags, '--env=production'
set :reload_command, 'sudo service php7.1-fpm reload'
