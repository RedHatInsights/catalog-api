module Metadata
  module Ancillary
    extend ActiveSupport::Concern

    included do
      has_one :ancillary_metadata, :as => :resource, :dependent => :destroy

      before_create   :update_metadata
      after_undiscard :update_metadata
    end

    def update_metadata
      if ancillary_metadata
        return if ancillary_metadata.destroyed?
      else
        build_ancillary_metadata
      end

      update_ancillary_metadata

      ancillary_metadata.save! unless new_record?
    end
  end
end
