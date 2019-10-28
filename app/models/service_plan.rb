class ServicePlan < ApplicationRecord
  include Discard::Model
  acts_as_tenant(:tenant)

  belongs_to :portfolio_item
  validates :base, :presence => true
end
