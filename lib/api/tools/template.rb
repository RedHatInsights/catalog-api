module Api
  module Tools
    class Template < Versioning
      def initialize(version, controller_names)
        @version = version
        @controller_names = controller_names
      end

      def controller(controller_name)
<<RUBY
module Api
  module V#{@version}
    class #{controller_name} < ApplicationController
    end
  end
end
RUBY
      end

      def write_templates
        @controller_names.each do |controller_name|
          file_name = "app/controllers/api/v#{@version}/#{controller_name.tableize.singularize}.rb"
          write(file_name, controller(controller_name))
        end
      end
    end
  end
end
