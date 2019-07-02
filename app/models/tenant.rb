class Tenant < ApplicationRecord
  validates :external_tenant, :uniqueness => true, :presence => true

  after_initialize :setup_settings, :unless => Proc.new { settings.nil? }

  def setup_settings
    settings.keys.each do |key|
      define_singleton_method(key) do
        settings[key]
      end
    end
  end
end
