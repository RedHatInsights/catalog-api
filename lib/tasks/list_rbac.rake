require 'rake'

namespace :catalog do
  namespace :rbac do
    namespace :list do
      options = {}
      options[:user_file] = ENV['USER_FILE']
      options[:debug] = ENV['DEBUG']
      desc "List groups for a tenant"
      task :groups => :environment do
        raise "Please provide a user credential yaml file" unless ENV['USER_FILE']
        RBAC::Tools::Group.new(options).process
      end

      desc "List roles for a tenant"
      task :roles => :environment do
        raise "Please provide a user credential yaml file" unless ENV['USER_FILE']
        RBAC::Tools::Role.new(options).process
      end

      desc "List policies for a tenant"
      task :policies => :environment do
        raise "Please provide a user credential yaml file" unless ENV['USER_FILE']
        RBAC::Tools::Policy.new(options).process
      end
    end
  end
end
