source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.1.7'
# Use Puma as the app server
gem 'puma', '~> 3.7'
gem 'mongoid'
## gem 'bson_ext'
gem "bcrypt-ruby", :require => "bcrypt"
gem 'jwt'
gem 'simple_command'
gem 'mongo'
# gem mongoid
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
#gem 'bcrypt', '~> 3.1.7'

gem 'mongoid-bcrypt-ruby'

gem 'activemodel-serializers-xml'
gem 'active_model_serializers'
gem 'whenever', require: false
gem 'delayed_job_mongoid'


# Use soft delete for records
gem 'mongoid_paranoia'

# for paginating the response data
gem 'will_paginate', '~> 3.1.0'


# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
gem 'rack-cors'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
