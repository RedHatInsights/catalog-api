require 'rake'

namespace :catalog do
  desc "Seed RBAC data given a seed yaml file and an user yaml file"
  task :seed_rbac_data => :environment do
    raise "Please provide a seed yaml file" unless ENV['SEED_FILE']
    raise "Please provide a user yaml file" unless ENV['USER_FILE']
    obj = RBAC::Seed.new(ENV['SEED_FILE'], ENV['USER_FILE'])
    obj.process
  end
end
