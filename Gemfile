source 'https://rubygems.org'

gem 'rails', '~> 5.2.2'

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
gem 'discard', '~> 1.0'
gem 'jbuilder', '~> 2.0'
gem 'manageiq-loggers', '~> 0.1'
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

#
# Custom Gemfile modifications
#
# To develop a gem locally and override its source to a checked out repo
#   you can use this helper method in bundler.d/*.rb e.g.
#
# override_gem 'topological_inventory-core', :path => "../topological_inventory-core"
#
def override_gem(name, *args)
  if dependencies.any?
    raise "Trying to override unknown gem #{name}" unless (dependency = dependencies.find { |d| d.name == name })
    dependencies.delete(dependency)

    calling_file = caller_locations.detect { |loc| !loc.path.include?("lib/bundler") }.path
    calling_dir  = File.dirname(calling_file)

    args.last[:path] = File.expand_path(args.last[:path], calling_dir) if args.last.kind_of?(Hash) && args.last[:path]
    gem(name, *args).tap do
      warn "** override_gem: #{name}, #{args.inspect}, caller: #{calling_file}" unless ENV["RAILS_ENV"] == "production"
    end
  end
end

# Load other additional Gemfiles
#   Developers can create a file ending in .rb under bundler.d/ to specify additional development dependencies
Dir.glob(File.join(__dir__, 'bundler.d/*.rb')).each { |f| eval_gemfile(File.expand_path(f, __dir__)) }
