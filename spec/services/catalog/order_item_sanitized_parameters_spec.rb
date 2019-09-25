describe Catalog::OrderItemSanitizedParameters, :type => :service do
  let(:subject) { described_class.new(params) }
  let(:params) { ActionController::Parameters.new('order_item_id' => order_item.id) }

  before do
    allow(ManageIQ::API::Common::Request).to receive(:current_forwardable).and_return(default_headers)
  end

  around do |example|
    with_modified_env(:TOPOLOGICAL_INVENTORY_URL => "http://localhost") do
      example.call
    end
  end

  describe "#process" do
    let(:order_item) { create(:order_item, :service_plan_ref => service_plan_ref) }

    context "when there is a valid service_plan_ref" do
      let(:service_plan_ref) { "777" }
      let(:service_plan_response) do
        TopologicalInventoryApiClient::ServicePlan.new(
          :name               => "Plan A",
          :id                 => "1",
          :description        => "Plan A",
          :create_json_schema => {:schema => {:fields => fields}}
        )
      end

      before do
        stub_request(:get, "http://localhost/api/topological-inventory/v1.0/service_plans/777")
          .to_return(:status => 200, :body => service_plan_response.to_json, :headers => default_headers)
      end

      context "ddf parameters" do
        let(:fields) do
          [{
            :name         => "Totally not a pass",
            :type         => "password",
            :label        => "Totally not a pass",
            :component    => "text-field",
            :helperText   => "",
            :isRequired   => true,
            :initialValue => ""
          }, {
            :name         => "most_important_var1",
            :label        => "secret field 1",
            :component    => "textarea-field",
            :helperText   => "Has no effect on anything, ever.",
            :initialValue => ""
          }, {
            :name         => "token idea",
            :label        => "field 1",
            :component    => "textarea-field",
            :helperText   => "Don't look.",
            :initialValue => ""
          }]
        end

        context "when the api call is successful" do
          it "returns 3 masked values" do
            result = subject.process

            expect(result.values.select { |v| v == described_class::MASKED_VALUE }.count).to eq(3)
          end
        end

        context "when the api call is not successful" do
          before do
            stub_request(:get, "http://localhost/api/topological-inventory/v1.0/service_plans/777")
              .to_raise(TopologicalInventoryApiClient::ApiError)
          end

          it "handles the exception and reraises a StandardError" do
            expect { subject.process }.to raise_error(StandardError)
          end
        end
      end
    end

    context "when the service plan ref is 'DNE'" do
      let(:service_plan_ref) { "DNE" }
      let(:fields) { [] }

      it "does not call the api" do
        subject.process
        expect(a_request(:any, /localhost/)).not_to have_been_made
      end

      it "returns an empty hash" do
        expect(subject.process).to eq({})
      end
    end
  end
end
