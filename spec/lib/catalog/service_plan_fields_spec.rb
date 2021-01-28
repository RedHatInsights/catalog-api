describe Catalog::ServicePlanFields, :type => [:service, :inventory, :current_forwardable] do
  describe "#process" do
    let(:order) { create(:order) }
    let(:order_item) { create(:order_item, :order => order, :portfolio_item => portfolio_item) }
    let(:portfolio_item) { create(:portfolio_item, :portfolio => portfolio, :service_plans => [service_plan]) }
    let(:portfolio) { create(:portfolio) }
    let(:task) { CatalogInventoryApiClient::Task.new(:id => "123", :output => {:applied_inventories => applied_inventories}) }
    let(:fields) do
      [{
        'name'         => "param1",
        'type'         => "string",
        'label'        => "Param1",
        'component'    => "text-field",
        'helperText'   => "",
        'isRequired'   => true,
        'initialValue' => "val1"
      }, {
        'name'       => "most_important_var1",
        'label'      => "secret field 1",
        'component'  => "textarea-field",
        'helperText' => ""
      }]
    end
    let(:subject) { described_class.new(order_item) }

    context 'when service_plan has modified' do
      let(:modified_fields) { [fields[0]] }
      let(:service_plan) { create(:service_plan, :base => {:schema => {:fields => fields}}, :modified => {:schema => {:fields => modified_fields}}) }

      before do
        allow(Catalog::SurveyCompare).to receive(:changed?)
        allow(Catalog::DataDrivenFormValidator).to receive(:valid?)
      end

      it 'gets fields from modified schema' do
        expect(subject.process.fields).to eq(modified_fields)
      end
    end

    context 'when service_plan has only base' do
      let(:service_plan) { create(:service_plan, :base => {:schema => {:fields => fields}}, :modified => nil) }

      it 'gets fields from modified schema' do
        expect(subject.process.fields).to eq(fields)
      end
    end

    context 'when portfolio_item has no local service plan' do
      around do |example|
        Insights::API::Common::Request.with_request(default_request) { example.call }
      end

      let(:portfolio_item) { create(:portfolio_item, :portfolio => portfolio) }
      let(:order_item) { create(:order_item, :order => order, :portfolio_item => portfolio_item, :service_plan_ref => '777') }

      let(:service_plan_response) do
        CatalogInventoryApiClient::ServicePlan.new(
          :name               => "Plan A",
          :id                 => "1",
          :description        => "Plan A",
          :create_json_schema => {:schema => {:fields => fields}}
        )
      end

      before do
        stub_request(:get, catalog_inventory_url("service_plans/777"))
          .to_return(:status => 200, :body => service_plan_response.to_json, :headers => default_headers)
      end

      it 'gets fields live from inventory' do
        expect(subject.process.fields).to eq(fields)
      end
    end

    context 'when portfolio_item has no service plan' do
      let(:portfolio_item) { create(:portfolio_item, :portfolio => portfolio) }
      let(:order_item) { create(:order_item, :order => order, :portfolio_item => portfolio_item, :service_plan_ref => nil) }

      it 'gets no fields' do
        expect(subject.process.fields).to be_empty
      end
    end
  end
end
