module Catalog
  class Settings
    attr_reader :values

    CONFIG_FILE = "config/settings.yml".freeze
    NAMESPACE = "default".freeze

    def initialize(namespace = nil, config_file = nil)
      load(namespace || NAMESPACE, config_file || CONFIG_FILE)
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
