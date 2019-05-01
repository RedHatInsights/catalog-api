require 'rake'

namespace :catalog do
  namespace :rbac do
    namespace :list do
      options = {}
      desc "List groups for a tenant"
      task :groups => :environment do
        raise "Please provide a user credential yaml file" unless ENV['USER_FILE']
        options[:user_file] = ENV['USER_FILE']
        RBAC::Tools::Group.new(options).process
      end

      desc "List roles for a tenant"
      task :roles => :environment do
        raise "Please provide a user credential yaml file" unless ENV['USER_FILE']
        options[:user_file] = ENV['USER_FILE']
        RBAC::Tools::Role.new(options).process
      end
    end
  end
end
