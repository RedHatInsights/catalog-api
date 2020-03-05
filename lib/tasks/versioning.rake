require 'rake'

namespace :api do
  namespace :versioning do
    desc "Add minor version [new_version,previous,controllers] rake api:versioning:minor['1x2','1x1','TestController;TestTwoController']"
    task :minor, [:new_version, :previous_version, :controllers] => :environment do |_task, args|
      controllers = args.controllers ? args.controllers.split(';') : []
      new_version = args.new_version
      previous_version = args.previous_version
      Api::Tools::Versioning.build_new(new_version, previous_version, controllers)
    end

    desc "Add major version [new_major,previous] rake api:versioning:major['2x0','1x9','TestControllerOne;TestTwoController']"
    task :major, [:new_version, :previous_version, :controllers] => :environment do |_task, args|
      controllers = args.controllers ? args.controllers.split(';') : []
      new_version = args.new_version
      previous_version = args.previous_version
      Api::Tools::Versioning.build_new(new_version, previous_version, controllers)
    end

    desc "Remove version [version_to_remove, restore_version] rake api:versioning:remove['1x2','1x1']"
    task :remove, [:version_to_remove, :restore_version] => :environment do |_task, args|
      version_to_remove = args.version_to_remove
      restore = args.restore_version
      Api::Tools::Versioning.remove(version_to_remove, restore)
    end
  end
end
