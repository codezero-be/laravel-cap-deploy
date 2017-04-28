set :deploy_config_path, 'deploy/deploy.rb'
set :stage_config_path,  'deploy/stages'

# Load DSL and set up stages
require 'capistrano/setup'

# Include default deployment tasks
require 'capistrano/deploy'

# Include composer tasks
require 'capistrano/composer'

# Load custom tasks from `lib/capistrano/tasks` if you have any defined
#Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }
