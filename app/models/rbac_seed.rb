class RbacSeed < ApplicationRecord
  validates :external_tenant, :uniqueness => true
  validates :external_tenant, :presence => true

  scope :seeded, ->(request) { find_by(:external_tenant => request.tenant) }
end
