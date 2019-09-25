module Catalog
  module JsonSchemaReader
    def read_json_schema(filename)
      template_file = File.read(Rails.root.join("schemas", "json", filename))

      JSON.parse(ERB.new(template_file).result(binding))
    end
  end
end
