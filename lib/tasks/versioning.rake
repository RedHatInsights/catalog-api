require 'rake'

namespace :api do
  namespace :versioning do
    desc "Add minor version"
    task :minor, [:version] => :environment do |_task, args|
      version = args.version
      Api::Tools::Versioning.build_new(version)
    end

    desc "Add major version"
    task :major, [:version] => :environment do |_task, args|
      version = args.version
      Api::Tools::Versioning.build_new(version)
    end

    desc "Deprecate version"
    task :deprecate, [:version] => :environment do |_task, args|

    end
  end
end
