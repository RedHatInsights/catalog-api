module Api
  module V1x0
    module Catalog
      class SoftDelete
        attr_reader :restore_key

        def initialize(record)
          @record = record
        end

        def process
          @record.discard!
          @restore_key = Digest::SHA1.hexdigest(@record.discarded_at.to_s)

          self
        rescue Discard::DiscardError
          raise Discard::DiscardError, "#{@record.class} #{@record.id} cannot be deleted: #{@record.errors[:base].join('; ')}"
        end
      end
    end
  end
end
