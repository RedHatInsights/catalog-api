class Icon < ApplicationRecord
  acts_as_tenant(:tenant)

  belongs_to :portfolio_item
  validates :data, :presence => true
end
