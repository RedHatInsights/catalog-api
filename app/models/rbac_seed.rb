class RbacSeed < ApplicationRecord
  validates :external_tenant, :uniqueness => true
  validates :external_tenant, :presence => true

  scope :seeded, ->(user) { find_by(:external_tenant => user.tenant) }
end
