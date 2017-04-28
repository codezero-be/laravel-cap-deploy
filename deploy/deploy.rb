# config valid only for current version of Capistrano
lock '3.4.0'

# gem install capistrano
# gem install capistrano-composer

# App Settings
set :branch, ask('branch to deploy', 'master')
set :scm, :git
set :tmp_dir, '/tmp'

# Symlinks
set :linked_files, ['.env']
set :linked_dirs,  ['storage']

# Subdirectories of linked dirs that should be created
set :linked_subdirs, [
    'storage/app',
    'storage/framework',
    'storage/framework/cache',
    'storage/framework/sessions',
    'storage/framework/views',
    'storage/logs'
]

# Shared directories that should be made writable
set :writable_linked_dirs, [
    'storage/app',
    'storage/framework',
    'storage/framework/cache',
    'storage/framework/sessions',
    'storage/framework/views',
    'storage/logs'
]

# Release directories that should be made writable
set :writable_release_dirs, [
    'bootstrap/cache'
]

# Composer, Laravel & sudo
set :composer_roles, :all
set :laravel_roles, :all
set :sudo_reload_roles, :all

# Log level
set :log_level, :info

namespace :setup do

    task :shared do
        on roles :all do
            fetch(:linked_subdirs).each do |dir|
                execute 'mkdir', '-p', "#{shared_path}/#{dir}"
            end
            fetch(:writable_linked_dirs).each do |dir|
                execute 'chmod', '775', "#{shared_path}/#{dir}"
            end
        end
    end

    task :env do
        on roles fetch(:laravel_roles) do
            if test(" ! [ -f #{shared_path}/.env ]")
                if test("[ -f #{current_path}/.env ]")
                    execute "mv #{current_path}/.env #{shared_path}/.env"
                else
                    execute "touch #{shared_path}/.env"
                end
            end
        end
    end

    task :remove_current do
        on roles :all do
            if test("[ -d #{current_path} ]")
                execute "rm -rf #{current_path}"
            end
        end
    end

end

namespace :db do

    task :migrate do
        on roles fetch(:laravel_roles) do
            within release_path do
                execute :php, :artisan, "migrate", "--force", fetch(:laravel_artisan_flags)
            end
        end
    end

    task :rollback do
        on roles fetch(:laravel_roles) do
            within release_path do
                execute :php, :artisan, "migrate:rollback", "--force", fetch(:laravel_artisan_flags)
            end
        end
    end

    task :refresh do
        on roles fetch(:laravel_roles) do
            within release_path do
                execute :php, :artisan, "migrate:refresh", "--force", fetch(:laravel_artisan_flags)
            end
        end
    end

    task :reset do
        on roles fetch(:laravel_roles) do
            within release_path do
                execute :php, :artisan, "migrate:reset", "--force", fetch(:laravel_artisan_flags)
            end
        end
    end

    task :seed do
        on roles fetch(:laravel_roles) do
            within release_path do
                execute :php, :artisan, "db:seed", "--force", fetch(:laravel_artisan_flags)
            end
        end
    end

end

namespace :cache do

    task :clear do
        on roles fetch(:laravel_roles) do
            within release_path do
                execute :php, :artisan, "cache:clear", fetch(:laravel_artisan_flags)
                execute :php, :artisan, "view:clear", fetch(:laravel_artisan_flags)
                execute :php, :artisan, "route:clear", fetch(:laravel_artisan_flags)
                execute :php, :artisan, "config:clear", fetch(:laravel_artisan_flags)
            end
        end
    end

    task :routes do
        on roles fetch(:laravel_roles) do
            within release_path do
                execute :php, :artisan, "route:cache", fetch(:laravel_artisan_flags)
            end
        end
    end

    task :config do
        on roles fetch(:laravel_roles) do
            within release_path do
                execute :php, :artisan, "config:cache", fetch(:laravel_artisan_flags)
            end
        end
    end

    task :refresh do
        invoke('cache:clear')
        invoke('cache:routes')
        invoke('cache:config')
    end

end

namespace :queue do

    task :restart do
        on roles fetch(:laravel_roles) do
            within current_path do
                execute :php, :artisan, "queue:restart"
            end
        end
    end

end

namespace :server do

    task :reload do
        on roles fetch(:sudo_reload_roles) do
            execute fetch(:reload_command)
        end
    end

end

namespace :deploy do

    task :setup do
        invoke('setup:shared')
        invoke('setup:env')
        invoke('setup:remove_current')
    end

    task :permissions do
        on roles :all do
            within release_path do
                fetch(:writable_release_dirs).each do |dir|
                    execute 'chmod', '775', dir
                end
            end
        end
    end

    task :optimize do
        on roles fetch(:laravel_roles) do
            within release_path do
                execute :php, :artisan, "optimize", fetch(:laravel_artisan_flags)
            end
        end
    end

    task :up do
        on roles fetch(:laravel_roles) do
            within release_path do
                execute :php, :artisan, "up"
            end
        end
    end

    task :down do
        on roles fetch(:laravel_roles) do
            within release_path do
                execute :php, :artisan, "down"
            end
        end
    end

    # Run extra tasks after installing a new release,
    # but before updating symlinks
    after :updated, "deploy:permissions"
    after :updated, "deploy:optimize"
    after :updated, "db:migrate"

    # Reload PHP-FPM after updating the symlinks
    after :published, "server:reload"

    # Clear cache after publishing
    after :published, "cache:clear"
    after :published, "cache:routes"
    after :published, "cache:config"

    # Restart any queue workers
    # after reloading PHP-FPM and
    # clearing the cache
    after :published, "queue:restart"

    # Extra rollback tasks
    after :rollback, "server:reload"
    after :rollback, "cache:clear"
    after :rollback, "cache:routes"
    after :rollback, "cache:config"
    after :rollback, "queue:restart"

end
