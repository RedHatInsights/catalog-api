class Tenant < ApplicationRecord
  validates :external_tenant, :uniqueness => true, :presence => true
end
