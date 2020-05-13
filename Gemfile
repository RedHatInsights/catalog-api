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
  gem 'shoulda-matchers'
  gem 'simplecov', '~> 0.17.1'
  gem 'webmock'
end

group :development do
  gem 'listen', '~> 3.0.5'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

gem 'dhasher'
gem 'discard', :git => 'https://github.com/jhawthorn/discard', :branch => 'master'
gem 'insights-api-common', '~> 4.0'
gem 'jbuilder', '~> 2.0'
gem 'manageiq-loggers', '~> 0.2'
gem 'manageiq-messaging', '~> 0.1.2', :require => false
gem 'mimemagic', '~> 0.3.3'
gem 'more_core_extensions', '~>3.5'
gem 'pg', '~> 1.0', :require => false
gem 'prometheus-client', '~> 0.8.0'
gem 'puma', '~> 3.12.4'
gem 'pundit'
gem 'rack-cors', '>= 1.0.4'
gem 'rest-client', '>= 1.8.0'
gem 'sources-api-client', '~> 1.0'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

gem 'topological_inventory-api-client', '~> 2.0'

gem 'insights-approval-api-client', '~> 1.2'
