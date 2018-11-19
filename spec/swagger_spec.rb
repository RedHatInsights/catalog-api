IGNORE =  %w(ServicePlan CreatePortfolioItem AddPortfolioItem)
describe "Swagger stuff" do
  let(:rails_routes) do
    Rails.application.routes.routes.each_with_object([]) do |route, array|
      r = ActionDispatch::Routing::RouteWrapper.new(route)
      next if r.internal? # Don't display rails routes
      next if r.engine? # Don't care right now...

      array << {:verb => r.verb, :path => r.path.split("(").first.sub(/:[_a-z]*id/, ":id")}
    end
  end

  let(:swagger_routes) { Api::Docs.routes }

  describe "Routing" do
    include Rails.application.routes.url_helpers

    #it "routes match" do
    #  redirect_routes = [{:path=>"/api/v0/*path", :verb=>"DELETE|GET|OPTIONS|PATCH|POST|PUT"}]
    #  expect(rails_routes).to match_array(swagger_routes + redirect_routes)
    #end

    context "customizable route prefixes" do
      after { Rails.application.reload_routes! }

      #it "with a random prefix" do
      #  stub_const("ENV", ENV.to_h.merge("PATH_PREFIX" => random_path))
      #  Rails.application.reload_routes!

      #  expect(ENV["PATH_PREFIX"]).not_to be_nil
      #  expect(api_v0x0_sources_url(:only_path => true)).to eq("/#{ENV["PATH_PREFIX"]}/v0.0/sources")
      #end
    end

    def words
      @words ||= File.readlines("/usr/share/dict/words", :chomp => true)
    end

    def random_path_part
      rand(1..5).times.collect { words.sample }.join("_")
    end

    def random_path
      rand(1..10).times.collect { random_path_part }.join("/")
    end
  end

  describe "Model serialization" do
    let(:doc) { Api::Docs[version] }
    let(:order) { Order.create!(doc.example_attributes("Order").symbolize_keys.merge(:tenant => tenant, :state => "Created", :order_items => [])) }
    let(:tenant) { Tenant.create! }
    let(:service_parameters) { {} }
    let(:provider_control_parameters) { {} }
    let(:order_item) { OrderItem.create!(doc.example_attributes("OrderItem").symbolize_keys.merge(:tenant => tenant, :count => 1, :service_parameters => service_parameters, :provider_control_parameters => provider_control_parameters, :order_id => order.id, :service_plan_ref => SecureRandom.uuid, :portfolio_item_id => portfolio_item.id)) }
    let(:portfolio) { Portfolio.create!(doc.example_attributes("Portfolio").symbolize_keys.merge(:tenant => tenant, :name => "blah", :description => "blah desc")) }
    let(:portfolio_item) { PortfolioItem.create!(doc.example_attributes("PortfolioItem").symbolize_keys.merge(:tenant => tenant, :name => "blah", :description => "blah desc", :service_offering_ref => SecureRandom.uuid)) }
    let(:progress_message) { ProgressMessage.create!(doc.example_attributes("ProgressMessage").symbolize_keys.merge(:tenant => tenant))  }

    context "v0.0" do
      let(:version) { "0.0" }
      Api::Docs["0.0"].definitions.each do |definition_name, schema|
        next if definition_name.in?(["Id"] + IGNORE)

        it "#{definition_name} matches the JSONSchema" do
          const = definition_name.constantize
          expect(send(definition_name.underscore).as_json(:prefixes => ["api/v0x0/#{definition_name.underscore}"])).to match_json_schema("0.0", definition_name)
        end
      end
    end
  end
end
