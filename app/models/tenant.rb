class Tenant < ApplicationRecord
  scope :current, ->(request) { where(:external_tenant => request.tenant) }

  validates :external_tenant, :uniqueness => true, :presence => true

  before_validation :setup_settings, :unless => proc { settings.nil? }
  after_initialize :setup_settings, :unless => proc { settings.nil? }

  def self.scoped_tenants
    current(Insights::API::Common::Request.current)
  rescue NoMethodError
    []
  end

  def add_setting(name, value)
    raise Catalog::InvalidParameter if settings[name.to_s].present?

    settings[name] = value
    save!
  end

  def update_setting(name, value)
    raise ActiveRecord::RecordNotFound if settings[name.to_s].nil?

    settings[name] = value
    save!
  end

  def delete_setting(setting)
    raise ActiveRecord::RecordNotFound if settings[setting.to_s].nil?

    settings.delete(setting.to_s)
    save!
  end

  private

  def setup_settings
    settings.keys.each do |key|
      define_singleton_method(key) do
        settings[key]
      end
    end
  end
end
