describe "OpenAPI stuff" do
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
    Api::Docs.routes.select do |spec_route|
      published_versions.include?(spec_route[:path].match(/\/api\/catalog\/v([\d]+\.[\d])\//)[1])
    end
  end

  let(:exception_routes) do
    [
      {:path => "/404", :verb => "GET"},
      {:path => "/:status", :verb => ""}
    ]
  end

  let(:internal_api_routes) do
    [
      {:path => "/internal/v0/*path", :verb => "POST"},
      {:path => "/internal/v1.0/notify/approval_request/:id", :verb => "POST"},
      {:path => "/internal/v1.0/notify/order_item/:id", :verb => "POST"},
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
      it "matches the routes" do
        redirect_routes = [
          {:path => "#{path_prefix}/#{app_name}/v1/*path", :verb => "DELETE|GET|OPTIONS|PATCH|POST"}
        ]
        expect(rails_routes).to match_array(open_api_routes + redirect_routes + exception_routes + internal_api_routes)
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

    def words
      @words ||= File.readlines("/usr/share/dict/words").collect(&:strip)
    end

    def random_path_part
      rand(1..5).times.collect { words.sample }.join("_")
    end

    def random_path
      rand(1..10).times.collect { random_path_part }.join("/")
    end
  end

  describe "Model serialization" do
    context "v1.0" do
      ActiveRecord::Base.connection.tables.each do |table|
        next if %w[tenants schema_migrations ar_internal_metadata].include?(table)

        model_name = table.singularize.camelize
        model = model_name.constantize
        Api::Docs["1.0"].definitions[model_name].properties.keys.each do |attr|
          it "The JSON Schema #{attr} matches the #{table} attribute #{attr}" do
            expect(model.new.attributes.include?(attr)).to be_truthy
          end
        end
      end
    end
  end
end
