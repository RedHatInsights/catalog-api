module Api
  module V1x0
    module Catalog
      module DiscardRestore
        extend ActiveSupport::Concern

        CHILD_DISCARD_TIME_LIMIT = 30

        module ClassMethods
          def destroy_dependencies(*klass_names)
            klass_names.each do |klass|
              define_method "discard_#{klass}" do
                collection = send(klass)

                if collection.map(&:discard).any? { |result| result == false }
                  collection.kept.each do |instance|
                    Rails.logger.error("#{instance} ID #{instance.id} failed to be discarded")
                  end

                  err = "Failed to discard #{klass} from #{self.class} id: #{id} - not discarding #{self.class}"
                  Rails.logger.error(err)
                  raise Discard::DiscardError, err
                end
              end

              define_method "restore_#{klass}" do
                collection = send(klass)

                instances_to_restore = collection.with_discarded.discarded.select do |instance|
                  (instance.discarded_at.to_i - discarded_at.to_i).abs < CHILD_DISCARD_TIME_LIMIT
                end
                if instances_to_restore.map(&:undiscard).any? { |result| result == false }
                  instances_to_restore.select(&:discarded?).each do |instance|
                    Rails.logger.error("#{klass} ID #{instance}.id} failed to be restored")
                  end

                  err = "Failed to restore #{klass} from #{self.class} id: #{id} - not restoring #{self.class}"
                  Rails.logger.error(err)
                  raise Discard::DiscardError, err
                end
              end

              before_discard "discard_#{klass}".to_sym
              before_undiscard "restore_#{klass}".to_sym
            end
          end
        end
      end
    end
  end
end
