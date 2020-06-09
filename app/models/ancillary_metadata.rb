class AncillaryMetadata < ApplicationRecord
  NON_METADATA_ATTRIBUTES = %w[id tenant_id resource_id resource_type created_at].freeze
  belongs_to :resource, :polymorphic => true

  def metadata_attributes
    attributes.except(*NON_METADATA_ATTRIBUTES)
  end
end
