module Api
  module V1x0
    module Catalog
      class SoftDeleteRestore
        def initialize(record, restore_key)
          @record = record
          @restore_key = restore_key
        end

        def process
          if @restore_key == Digest::SHA1.hexdigest(@record.discarded_at.to_s)
            @record.undiscard
          else
            raise Catalog::NotAuthorized, "Wrong key to restore deleted record #{@record.id}"
          end

          self
        end
      end
    end
  end
end
