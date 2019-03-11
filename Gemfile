source 'https://rubygems.org'

plugin 'bundler-inject', '~> 1.1'
require File.join(Bundler::Plugin.index.load_paths("bundler-inject")[0], "bundler-inject") rescue nil

gem 'rails', '>= 5.2.2.1', '~> 5.2.2'

group :development, :test do
  gem 'byebug', platform: :mri
  gem 'climate_control'
  gem 'factory_bot_rails'
  gem 'rspec-mocks'
  gem 'rspec-rails'
  gem 'simplecov'
end

group :development do
  gem 'listen', '~> 3.0.5'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

gem 'acts_as_tenant'
gem 'discard', :git => 'https://github.com/jhawthorn/discard', :branch => 'master'
gem 'jbuilder', '~> 2.0'
gem 'manageiq-loggers', '~> 0.1'
gem 'manageiq-messaging', '~> 0.1.2', :require => false
gem 'more_core_extensions', '~>3.5'
gem 'pg', '~> 1.0', :require => false
gem 'prometheus-client', '~> 0.8.0'
gem 'puma', '~> 3.0'
gem 'rack-cors', '>= 0.4.1'
gem 'rest-client', '>= 1.8.0'
gem 'swagger_ui_engine'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

gem 'manageiq-api-common', :git => 'https://github.com/ManageIQ/manageiq-api-common', :branch => 'master'
gem 'topological_inventory-api-client', :git => "https://github.com/mkanoor/topological_inventory-api-client", :branch => "master"

gem 'rbac-api-client', :git => "https://github.com/mkanoor/rbac_api_client", :branch => "master"
