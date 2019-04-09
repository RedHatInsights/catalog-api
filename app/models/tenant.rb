class Tenant < ApplicationRecord
  validates :external_tenant, :uniqueness => true, :presence => true

  def self.tenancy_enabled?
    ENV["BYPASS_TENANCY"].blank?
  end
end
