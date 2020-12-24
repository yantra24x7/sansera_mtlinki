workers 2

# Min and Max threads per worker
threads 1, 6

app_dir = File.expand_path("../..", __FILE__)
shared_dir = "#{app_dir}/shared"

# Default to production
rails_env = ENV['RAILS_ENV'] || "development"
environment rails_env

# Set up socket location
bind "unix://#{shared_dir}/sockets/puma.sock"

# Logging
stdout_redirect "#{shared_dir}/log/puma.stdout.log", "#{shared_dir}/log/puma.stderr.log", true

# Set master PID and state locations
pidfile "#{shared_dir}/pids/puma.pid"
state_path "#{shared_dir}/pids/puma.state"
activate_control_app

on_worker_boot do
 #  require "mongoid"
   # require 'rails/mongoid'
   #  ActiveRecord::Base.connection.disconnect! rescue ActiveRecord::ConnectionNotEstablished
    # mongoid.establish_connection(YAML.load_file("#{app_dir}/config/mongoid.yml")[rails_env])
     # Mongoid.load!
     #  Mongoid.load!("#{app_dir}/config/mongoid.yml", [rails_env])
end
    
