require 'rake'

namespace :catalog do
  desc "Remove one or more users from a group"
  task :remove_users_from_group  => :environment do
    raise "Please provide a user credential yaml file" unless ENV['USER_FILE']
    raise "Please provide a comma separated list of user names" unless ENV['USERS']
    raise "Please provide a single group name" unless ENV['GROUP']
    options = {:mode => 'remove'}
    options[:users] = ENV['USERS']
    options[:group] = ENV['GROUP']
    options[:user_file] = ENV['USER_FILE']
    RBAC::UserMgmt.new(options).process
  end
end
