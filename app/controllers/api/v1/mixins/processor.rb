module Api
  module V1
    module Mixins
      module Processor
        def process_service(class_name, args, namespace: "Catalog")
          "V1x0::#{namespace}::#{class_name}".constantize.new(*args).process
        end
      end
    end
  end
end
