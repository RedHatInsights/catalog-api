class ProgressMessage < ApplicationRecord
  acts_as_tenant(:tenant)

  after_initialize :set_defaults, unless: :persisted?

  AS_JSON_ATTRIBUTES = %w(id level message received_at).freeze

  def as_json(_options = {})
    super.slice(*AS_JSON_ATTRIBUTES)
  end

  def set_defaults
    self.received_at = DateTime.now
  end
end
