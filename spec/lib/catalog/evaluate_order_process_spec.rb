describe Catalog::EvaluateOrderProcess, :type => :service do
  around do |example|
    Insights::API::Common::Request.with_request(default_request) { example.call }
  end

  describe "#process" do
    let(:service_plans) { instance_double(Api::V1x0::Catalog::ServicePlans, :items => ["id" => "service_plan_ref"]) }
    before do
      allow(Api::V1x0::Catalog::ServicePlans).to receive(:new).at_least(:once).and_return(service_plans)
      allow(service_plans).to receive(:process).at_least(:once).and_return(service_plans)
    end

    let(:order) { create(:order) }
    let!(:order_item) { create(:order_item, :order => order, :portfolio_item => portfolio_item) }
    let(:portfolio_item) { create(:portfolio_item, :portfolio => portfolio) }
    let(:portfolio) { create(:portfolio) }
    let(:task) { CatalogInventoryApiClient::Task.new(:id => "123", :output => {:applied_inventories => applied_inventories}) }
    let(:applied_inventories) { [] }
    let(:before_service_plan) { create(:service_plan, :base => {:schema => {:fields => fields}}, :modified => nil) }
    let(:after_service_plan) { create(:service_plan, :base => {:schema => {:fields => fields}}, :modified => nil) }
    let(:fields) do
      [{
        :name         => "param1",
        :type         => "string",
        :label        => "Param1",
        :component    => "text-field",
        :helperText   => "",
        :isRequired   => true,
        :initialValue => "val1"
      }, {
        :name       => "most_important_var1",
        :label      => "secret field 1",
        :component  => "textarea-field",
        :helperText => ""
      }]
    end

    subject { described_class.new(task, order, tag_resources).process }

    shared_examples_for "order with before/after itsm" do
      it "creates an order with three items" do
        subject
        expect(order.order_items.count).to eq(3)
        expect(order.order_items.first).to have_attributes(:process_sequence => 1, :process_scope => "before", :portfolio_item => before_portfolio_item, :service_parameters => {'param1' => 'val1'})
        expect(order.order_items.second).to have_attributes(:process_sequence => 2, :process_scope => 'product')
        expect(order.order_items.third).to have_attributes(:process_sequence => 3, :process_scope => "after", :portfolio_item => after_portfolio_item, :service_parameters => {'param1' => 'val1'})
      end
    end
      
    context "when there are no existing tags on the portfolio or portfolio_item" do
      let(:tag_resources) { [] }

      it "create an order with the product being the only item" do
        subject
        expect(order.order_items.count).to eq(1)
        expect(order.order_items.first).to have_attributes(:process_sequence => 1, :process_scope => 'product')
      end
    end

    context "when there are existing tags" do
      let(:before_portfolio_item) { create(:portfolio_item, :service_plans => [before_service_plan]) }
      let(:after_portfolio_item) { create(:portfolio_item, :service_plans => [after_service_plan]) }
      let(:order_process) { create(:order_process, :before_portfolio_item => before_portfolio_item, :after_portfolio_item  => after_portfolio_item) }
      let(:tag_resources) { Tags::CollectLocalOrderResources.new(:order_id => order.id).process.tag_resources }
      before { TagLink.create(:order_process_id => order_process.id, :tag_name => "/catalog/order_processes=#{order_process.id}") }

      context "when there is 1 existing tag on the portfolio" do
        before { portfolio.tag_add("order_processes", :namespace => "catalog", :value => order_process.id) }

        context "when both before and after portfolio items present in the order process" do
          it_behaves_like "order with before/after itsm"
        end

        context "when there is no before portfolio item" do
          let(:order_process) { create(:order_process, :after_portfolio_item => after_portfolio_item) }

          it "creates an order with product and after item" do
            subject
            expect(order.order_items.count).to eq(2)
            expect(order.order_items.first).to have_attributes(:process_sequence => 1, :process_scope => 'product')
            expect(order.order_items.second).to have_attributes(:process_sequence => 2, :process_scope => "after", :portfolio_item => after_portfolio_item, :service_parameters => {'param1' => 'val1'})
          end
        end

        context "when there is no after portfolio item" do
          let(:order_process) { create(:order_process, :before_portfolio_item => before_portfolio_item) }

          it "creates an order with before and product items" do
            subject
            expect(order.order_items.count).to eq(2)
            expect(order.order_items.first).to have_attributes(:process_sequence => 1, :process_scope => "before", :portfolio_item => before_portfolio_item, :service_parameters => {'param1' => 'val1'})
            expect(order.order_items.second).to have_attributes(:process_sequence => 2, :process_scope => 'product')
          end
        end
      end

      context "when there is 1 existing tag on the portfolio_item" do
        before { portfolio_item.tag_add("order_processes", :namespace => "catalog", :value => order_process.id) }

        it_behaves_like "order with before/after itsm"
      end

      context "when both the portfolio_item and portfolio have tags" do
        context "when the tags are the same" do
          before do
            portfolio_item.tag_add("order_processes", :namespace => "catalog", :value => order_process.id)
            portfolio.tag_add("order_processes", :namespace => "catalog", :value => order_process.id)
          end

          it_behaves_like "order with before/after itsm"
        end

        context "when has remote tags from inventory" do
          let(:tag_resources) do
            [{:app_name    => "catalog-inventory",
              :object_type => "ServiceInventory",
              :tags        => [
                :tag => "/catalog-inventory/order_processes=#{order_process.id}"
              ]}]
          end
          let(:remote_inventory_instance) { instance_double(Tags::CatalogInventory::RemoteInventory) }

          before do
            TagLink.create(:order_process_id => order_process.id, :tag_name => "/catalog-inventory/order_processes=#{order_process.id}")
          end

          it_behaves_like "order with before/after itsm"
        end

        context "when the tags are different" do
          let(:before_service_plan2) { create(:service_plan, :base => {:schema => {:fields => fields}}, :modified => nil) }
          let(:after_service_plan2) { create(:service_plan, :base => {:schema => {:fields => fields}}, :modified => nil) }
          let(:before_portfolio_item2) { create(:portfolio_item, :service_plans => [before_service_plan2]) }
          let(:after_portfolio_item2) { create(:portfolio_item, :service_plans => [after_service_plan2]) }
          let(:order_process2) { create(:order_process, :before_portfolio_item => before_portfolio_item2, :after_portfolio_item => after_portfolio_item2) }

          before do
            TagLink.create(:order_process_id => order_process2.id, :tag_name => "/catalog/order_processes=#{order_process2.id}")

            portfolio_item.tag_add("order_processes", :namespace => "catalog", :value => order_process.id)
            portfolio.tag_add("order_processes", :namespace => "catalog", :value => order_process2.id)
          end

          it "creates an order with 5 items" do
            subject
            expect(order.order_items.count).to eq(5)
            expect(order.order_items[0]).to have_attributes(:process_sequence => 1, :process_scope => "before", :portfolio_item => before_portfolio_item, :service_parameters => {'param1' => 'val1'})
            expect(order.order_items[1]).to have_attributes(:process_sequence => 2, :process_scope => "before", :portfolio_item => before_portfolio_item2, :service_parameters => {'param1' => 'val1'})
            expect(order.order_items[2]).to have_attributes(:process_sequence => 3, :process_scope => 'product')
            expect(order.order_items[3]).to have_attributes(:process_sequence => 4, :process_scope => "after", :portfolio_item => after_portfolio_item2, :service_parameters => {'param1' => 'val1'})
            expect(order.order_items[4]).to have_attributes(:process_sequence => 5, :process_scope => "after", :portfolio_item => after_portfolio_item, :service_parameters => {'param1' => 'val1'})
          end

          it "reorders itsm items according to order_process sequences" do
            order_process.move_internal_sequence(2) # push down order_process less priority than order_process2
            subject
            expect(order.order_items[0]).to have_attributes(:process_sequence => 1, :process_scope => "before", :portfolio_item => before_portfolio_item2, :service_parameters => {'param1' => 'val1'})
            expect(order.order_items[1]).to have_attributes(:process_sequence => 2, :process_scope => "before", :portfolio_item => before_portfolio_item, :service_parameters => {'param1' => 'val1'})
            expect(order.order_items[2]).to have_attributes(:process_sequence => 3, :process_scope => 'product')
            expect(order.order_items[3]).to have_attributes(:process_sequence => 4, :process_scope => "after", :portfolio_item => after_portfolio_item, :service_parameters => {'param1' => 'val1'})
            expect(order.order_items[4]).to have_attributes(:process_sequence => 5, :process_scope => "after", :portfolio_item => after_portfolio_item2, :service_parameters => {'param1' => 'val1'})
          end
        end
      end
    end
  end
end
