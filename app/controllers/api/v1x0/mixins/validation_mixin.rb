module Api
  module V1x0
    module Mixins
      module ValidationMixin
        def writeable_params_for_create
          attr_list = api_doc_definition.all_attributes - api_doc_definition.read_only_attributes

          params.permit(request_body_schema_keys | attr_list)
        end

        def request_body_schema_keys
          api_doc_content.dig("components", "schemas", request_body_schema_name, "properties")
                         .reject { |_k, v| v["readOnly"] == true }
                         .keys
        end

        def request_body_schema_name
          api_doc_content.dig("paths", "/#{controller_name}", "post", "requestBody", "content", "application/json", "schema", "$ref").split("/").last
        end

        def api_doc_content
          Insights::API::Common::OpenApi::Docs.instance[api_version].content
        end
      end
    end
  end
end
