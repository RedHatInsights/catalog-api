class Tenant < ApplicationRecord
  validates :external_tenant, :uniqueness => true, :presence => true

  after_initialize :setup_settings, :unless => proc { settings.nil? }

  def add_settings(setting)
    settings.merge!(setting)
    save!
  end

  def update_setting(setting)
    add_settings(setting)
  end

  def delete_setting(setting)
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
