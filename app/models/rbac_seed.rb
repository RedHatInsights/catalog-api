class RbacSeed < ApplicationRecord
  validates_uniqueness_of :external_tenant
  validates :external_tenant, :presence => true

  scope :seeded, ->(user) { find_by(:external_tenant => user.tenant) }
end
