require 'rake'

namespace :api do
  namespace :versioning do
    desc "Add minor version [new_version,previsou] rake api:versioning:minor['1x2','1x1']"
    task :minor, [:new_version, :previous_version] => :environment do |_task, args|
      new_version = args.new_version
      previous_version = args.previous_version
      Api::Tools::Versioning.build_new(new_version, previous_version)
    end

    desc "Add major version [new_major,previous] rake api:versioning:major['2x0','1x9']"
    task :major, [:new_version, :previous_version] => :environment do |_task, args|
      new_version = args.new_version
      previous_version = args.previous_version
      Api::Tools::Versioning.build_new(new_version, previous_version)
    end

    desc "Remove version [version_to_remove, restore_version] rake api:versioning:remove['1x2','1x1']"
    task :remove, [:version_to_remove, :restore_version] => :environment do |_task, args|
      version_to_remove = args.version_to_remove
      restore = args.restore_version
      Api::Tools::Versioning.remove(version_to_remove, restore)
    end
  end
end
