module Catalog
  class Settings
    attr_reader :values

    CONFIG_LOCATION = "config/settings.yml".freeze
    NAMESPACE = "default".freeze

    def initialize(namespace = nil, config_file = CONFIG_LOCATION)
      if namespace.nil?
        Rails.logger.debug("Loading default settings from #{CONFIG_LOCATION}")
        load(NAMESPACE, config_file)
      else
        load(namespace, config_file)
      end
    end

    private

    def load(namespace, config_file)
      @values = YAML.load_file(Rails.root.join(config_file))[namespace]

      @values.keys.each do |key|
        define_singleton_method(key) do
          @values[key]
        end
      end
    end
  end
end
