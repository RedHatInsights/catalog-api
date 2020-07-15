describe "OpenAPI stuff" do
  include RandomWordsSpecHelper

  PARSER_ATTRS = %w[readOnly nullable enum].freeze
  SKIP_TABLES = %w[tenants schema_migrations ar_internal_metadata rbac_seeds portfolio_tags tag_links
                   portfolio_item_tags order_process_tags tags order_processes images icons service_plans access_control_entries
                   access_control_permissions permissions ancillary_metadata].freeze

  let(:rails_routes) do
    Rails.application.routes.routes.each_with_object([]) do |route, array|
      r = ActionDispatch::Routing::RouteWrapper.new(route)
      next if r.internal? # Don't display rails routes
      next if r.engine? # Don't care right now...
      next if r.action == "invalid_url_error"

      array << {:verb => r.verb, :path => r.path.split("(").first.sub(/:[_a-z]*id/, ":id")}
    end
  end

  let(:open_api_routes) do
    published_versions = rails_routes.collect do |rails_route|
      (version_match = rails_route[:path].match(/\/api\/catalog\/v([\d]+\.[\d])\/openapi.json$/)) && version_match[1]
    end.compact
    ::Insights::API::Common::OpenApi::Docs.instance.routes.select do |spec_route|
      published_versions.include?(spec_route[:path].match(/\/api\/catalog\/v([\d]+\.[\d])\//)[1])
    end
  end

  let(:internal_api_routes) do
    [
      {:path => "/internal/v0/*path", :verb => "POST"},
      {:path => "/internal/v1.0/notify/approval_request/:id", :verb => "POST"},
      {:path => "/internal/v1.0/notify/task/:id", :verb => "POST"}
    ]
  end

  let(:health_check_routes) do
    [
      {:path => "/health", :verb => "GET"}
    ]
  end

  describe "Routing" do
    include Rails.application.routes.url_helpers
    let(:app_name)    { "catalog" }
    let(:path_prefix) { "/api" }

    before do
      stub_const("ENV", ENV.to_h.merge("PATH_PREFIX" => path_prefix, "APP_NAME" => app_name))
      Rails.application.reload_routes!
    end

    after(:all) do
      Rails.application.reload_routes!
    end

    context "with the openapi json" do
      let(:v1_path) {{:path => "#{path_prefix}/#{app_name}/v1/*path", :verb => "DELETE|GET|OPTIONS|PATCH|POST"}}
      it "matches the routes" do

        redirect_routes = [
          v1_path
        ]
        expect(rails_routes).to match_array(open_api_routes + redirect_routes + internal_api_routes + health_check_routes)
      end
    end

    context "customizable route prefixes" do
      let(:path_prefix) { random_path_part }
      let(:app_name)    { random_path }

      it "with a random prefix" do
        expect(ENV["PATH_PREFIX"]).not_to be_nil
        expect(ENV["APP_NAME"]).not_to be_nil
        expect(api_v1x0_orders_url(:only_path => true)).to eq("/#{URI.encode(ENV["PATH_PREFIX"])}/#{URI.encode(ENV["APP_NAME"])}/v1.0/orders")
      end

      it "with extra slashes" do
        ENV["PATH_PREFIX"] = "//example/path/prefix/"
        ENV["APP_NAME"] = "/appname/"
        Rails.application.reload_routes!
        expect(api_v1x0_orders_url(:only_path => true)).to eq("/example/path/prefix/appname/v1.0/orders")
      end

      it "doesn't use the APP_NAME when PATH_PREFIX is empty" do
        ENV["PATH_PREFIX"] = ""
        Rails.application.reload_routes!

        expect(ENV["APP_NAME"]).not_to be_nil
        expect(api_v1x0_orders_url(:only_path => true)).to eq("/api/v1.0/orders")
      end
    end
  end

  %w[1.0 1.1 1.2].each do |version|
    describe "Openapi schema attributes" do
      context "correctly configured" do
        ActiveRecord::Base.connection.tables.each do |table|
          next if SKIP_TABLES.include?(table)

          model_name = table.singularize.camelize
          doc = Api::Docs[version].definitions
          doc[model_name].properties.keys.each do |attr|
            it "The JSON Schema #{model_name} #{attr} includes valid #{PARSER_ATTRS} types for #{doc[model_name].properties[attr]}" do
              # If there is a validator on the Activerecord model and the schema does not include the
              #   'required' key
              if model_name.constantize.validators_on(attr.to_sym).present? && !doc[model_name].key?("required")
                expect(doc[model_name].properties[attr].keys & PARSER_ATTRS).not_to include(attr)
              # If there is a 'required' key on the schema
              elsif doc[model_name].key?("required")
                if doc[model_name]["required"].include?(attr)
                  expect([attr] & doc[model_name]["required"]).to include(attr)
                else
                  expect([attr] & doc[model_name]["required"]).not_to include(attr)
                end
              # If we find the 'boolean' type
              elsif doc[model_name].properties[attr]['type'] == 'boolean'
                expect(doc[model_name].properties[attr].keys).not_to include(PARSER_ATTRS)
              # Checking all the rest for PARSER_ATTRS
              else
                expect(doc[model_name].properties[attr].keys & PARSER_ATTRS).not_to be_empty
              end
            end
          end
        end
      end
    end

    describe "Model serialization" do
      context "specific version" do
        ActiveRecord::Base.connection.tables.each do |table|
          next if SKIP_TABLES.include?(table)

          model_name = table.singularize.camelize
          model = model_name.constantize
          Api::Docs[version].definitions[model_name].properties.keys.each do |attr|
            it "The JSON Schema #{attr} matches the #{table} attribute #{attr}" do
              expect(model.new.attributes.include?(attr)).to be_truthy
            end
          end
        end
      end
    end
  end
end
