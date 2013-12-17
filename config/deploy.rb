set :application, 'ignite-portland-proposals'
set :repo_url, 'git@github.com:stumpsyn/ignite-portland-proposals.git'

# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }
set :branch, :master

set :deploy_to, '/var/www/ignite-portland-proposals'
# set :scm, :git

# set :format, :pretty
# set :log_level, :debug
# set :pty, true

set :linked_files, %w{config/database.yml config/newrelic.yml config/secrets.yml config/errbit.yml}
set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

set :rails_env, :production  
set :default_env, {
  path: "#{shared_path}/ruby/bin:#{shared_path}/bin:$PATH:/sbin",
  rails_env: fetch(:rails_env)
}
# set :keep_releases, 5

before  'deploy:assets:precompile', 'deploy:migrate'
before  'deploy:migrate', 'deploy:create_shared_db_dir'

namespace :deploy do
  task :create_shared_db_dir do
    on roles(:app) do
      execute :mkdir, '-pv', "#{shared_path}/db"
    end
  end

  [:start, :stop, :reload].each do |t|
    desc '#{t} the application'
    task t do
      on roles(:app), in: :sequence, wait: 5 do
        execute :sudo, t, fetch(:application)
      end
    end
  end

  desc "restart the application (or start it, if it's not running)"
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute "sudo restart #{fetch(:application)} || sudo start #{fetch(:application)}"
    end
  end

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
       within release_path do
         execute :rake, 'tmp:cache:clear'
       end
    end
  end

  after :finishing, 'deploy:cleanup'
end

