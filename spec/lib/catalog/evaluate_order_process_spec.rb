describe Catalog::EvaluateOrderProcess, :type => :service do
  describe "#process" do
    let(:request) { default_request }
    let(:order) { create(:order) }
    let!(:order_item) { Insights::API::Common::Request.with_request(request) { create(:order_item, :order => order, :portfolio_item => portfolio_item) } }
    let(:portfolio_item) { create(:portfolio_item, :portfolio => portfolio) }
    let(:portfolio) { create(:portfolio) }
    let(:task) { TopologicalInventoryApiClient::Task.new(:id => "123", :context => {:applied_inventories => applied_inventories}) }
    let(:tag_resources) { Tags::CollectLocalOrderResources.new(:order_id => order.id).process.tag_resources }
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

    context "when there are no existing tags on the portfolio or portfolio_item" do
      let(:tag_resources) { [] }

      it "applies the process sequence of '1' to the order item" do
        subject
        expect(order.order_items.first.process_sequence).to eq(1)
      end

      it "applies the proccess scope of 'applicable' to the order item" do
        subject
        expect(order.order_items.first.process_scope).to eq("applicable")
      end

      it "does not add any other order items to the order" do
        subject
        expect(order.order_items.count).to eq(1)
      end
    end

    context "when there are existing tags" do
      let(:before_portfolio_item) { create(:portfolio_item, :service_plans => [before_service_plan]) }
      let(:after_portfolio_item) { create(:portfolio_item, :service_plans => [after_service_plan]) }
      let(:order_process) do
        create(:order_process,
               :before_portfolio_item => before_portfolio_item,
               :after_portfolio_item  => after_portfolio_item)
      end
      let(:service_plans_instance) { instance_double(Api::V1x0::Catalog::ServicePlans) }

      before do
        TagLink.create(:order_process_id => order_process.id, :tag_name => "/catalog/order_processes=#{order_process.id}")

        allow(Api::V1x0::Catalog::ServicePlans).to receive(:new).and_return(service_plans_instance)
        allow(service_plans_instance).to receive_message_chain(:process, :items).and_return([before_service_plan])
      end

      shared_examples_for "#one existing tag" do
        it "should return 3 order items" do
          subject
          expect(order.order_items.count).to eq(3)
        end

        it "should have right process sequences and scopes" do
          subject

          expect(order.order_items.first.process_sequence).to eq(1)
          expect(order.order_items.first.process_scope).to eq("before")

          expect(order.order_items.second.process_sequence).to eq(2)
          expect(order.order_items.second.process_scope).to eq("applicable")

          expect(order.order_items.last.process_sequence).to eq(3)
          expect(order.order_items.last.process_scope).to eq("after")
        end

        it "should have same insights_request_id" do
          subject
          expect(order.order_items.first.insights_request_id).to eq(request[:headers]["x-rh-insights-request-id"])
          expect(order.order_items.second.insights_request_id).to eq(request[:headers]["x-rh-insights-request-id"])
          expect(order.order_items.last.insights_request_id).to eq(request[:headers]["x-rh-insights-request-id"])
        end

        it "'before' and 'after' order_items should have valid service_parameters_raw" do
          subject
          expect(order.order_items.first.service_parameters_raw).to eq('param1' => 'val1')
          expect(order.order_items.last.service_parameters_raw).to eq('param1' => 'val1')
        end
      end

      context "when there is 1 existing tag on the portfolio" do
        before do
          portfolio.tag_add("order_processes", :namespace => "catalog", :value => order_process.id)
        end

        it_behaves_like "#one existing tag"

        context "when there is no before portfolio item" do
          let(:order_process) do
            create(:order_process, :after_portfolio_item => after_portfolio_item)
          end

          it "should return 2 order items" do
            subject
            expect(order.order_items.count).to eq(2)
          end

          it "should have right process sequences and scopes" do
            subject

            expect(order.order_items.first.process_sequence).to eq(1)
            expect(order.order_items.last.process_sequence).to eq(2)

            expect(order.order_items.first.process_scope).to eq("applicable")
            expect(order.order_items.last.process_scope).to eq("after")
          end

          it "'after' order_items should have valid service_parameters_raw" do
            subject
            expect(order.order_items.last.service_parameters_raw).to eq('param1' => 'val1')
          end
        end

        context "when there is no after portfolio item" do
          let(:order_process) do
            create(:order_process, :before_portfolio_item => before_portfolio_item)
          end

          it "should return 2 order items" do
            subject
            expect(order.order_items.count).to eq(2)
          end

          it "should have right process sequences and scopes" do
            subject

            expect(order.order_items.first.process_sequence).to eq(1)
            expect(order.order_items.last.process_sequence).to eq(2)

            expect(order.order_items.first.process_scope).to eq("before")
            expect(order.order_items.last.process_scope).to eq("applicable")
          end

          it "delegates creation of a 'before' order_item with a process sequence of 1" do
            subject
            expect(order.order_items.first.service_parameters_raw).to eq('param1' => 'val1')
          end
        end
      end

      context "when there is 1 existing tag on the portfolio_item" do
        before do
          portfolio_item.tag_add("order_processes", :namespace => "catalog", :value => order_process.id)
        end

        it_behaves_like "#one existing tag"
      end

      context "when both the portfolio_item and portfolio have tags" do
        context "when the tags are the same" do
          before do
            portfolio_item.tag_add("order_processes", :namespace => "catalog", :value => order_process.id)
            portfolio.tag_add("order_processes", :namespace => "catalog", :value => order_process.id)
          end

          it_behaves_like "#one existing tag"
        end

        context "when the tags are different" do
          let(:order_process2) do
            create(:order_process,
                   :before_portfolio_item => before_portfolio_item,
                   :after_portfolio_item  => after_portfolio_item)
          end

          before do
            TagLink.create(:order_process_id => order_process2.id, :tag_name => "/catalog/order_processes=#{order_process2.id}")
            TagLink.create(:order_process_id => order_process.id, :tag_name => "/catalog/order_processes=#{order_process.id}")

            portfolio_item.tag_add("order_processes", :namespace => "catalog", :value => order_process.id)
            portfolio.tag_add("order_processes", :namespace => "catalog", :value => order_process2.id)
          end

          it "should return 5 order items" do
            subject
            expect(order.order_items.count).to eq(5)
          end

          it "should return right process sequences and scopes" do
            subject
            expect(order.order_items.third.process_sequence).to eq(3)
            expect(order.order_items.third.process_scope).to eq("applicable")

            expect(order.order_items.first.process_scope).to eq("before")
            expect(order.order_items.second.process_scope).to eq("before")

            expect(order.order_items.fourth.process_scope).to eq("after")
            expect(order.order_items.last.process_scope).to eq("after")
          end
        end

        context "when has remote tags from topology" do
          let(:tag_resources) do
            [{:app_name    => "topology",
              :object_type => "ServiceInventory",
              :tags        => [
                :tag => "/topology/order_processes=#{order_process.id}"
              ]}]
          end
          let(:remote_inventory_instance) { instance_double(Tags::Topology::RemoteInventory) }

          before do
            TagLink.create(:order_process_id => order_process.id, :tag_name => "/topology/order_processes=#{order_process.id}")
          end

          it_behaves_like "#one existing tag"
        end
      end
    end
  end
end
