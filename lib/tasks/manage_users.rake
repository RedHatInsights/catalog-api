require 'rake'

namespace :catalog do
  desc "Add one or more users to a group"
  task :add_users_to_group => :environment do
    raise "Please provide a user credential yaml file" unless ENV['USER_FILE']
    raise "Please provide a comma separated list of user names" unless ENV['USERS']
    raise "Please provide a single group name" unless ENV['GROUP']
    options = {:mode => 'add'}
    options[:users] = ENV['USERS']
    options[:group] = ENV['GROUP']
    options[:user_file] = ENV['USER_FILE']
    RBAC::Tools::UserMgmt.new(options).process
  end

  desc "Remove one or more users from a group"
  task :remove_users_from_group  => :environment do
    raise "Please provide a user credential yaml file" unless ENV['USER_FILE']
    raise "Please provide a comma separated list of user names" unless ENV['USERS']
    raise "Please provide a single group name" unless ENV['GROUP']
    options = {:mode => 'remove'}
    options[:users] = ENV['USERS']
    options[:group] = ENV['GROUP']
    options[:user_file] = ENV['USER_FILE']
    RBAC::Tools::UserMgmt.new(options).process
  end
end
