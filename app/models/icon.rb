class Icon < ApplicationRecord
  acts_as_tenant(:tenant)
  include Discard::Model
  default_scope -> { kept }

  belongs_to :portfolio_item
  validates :data, :presence => true
end
