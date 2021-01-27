describe Catalog::OrderItemSanitizedParameters, :type => [:service, :inventory, :current_forwardable] do
  let(:subject) { described_class.new(order_item) }

  describe "#process" do
    let(:service_plan) { create(:service_plan, :base => {:schema => {:fields => fields}}, :modified => nil) }
    let(:portfolio_item) { create(:portfolio_item, :service_plans => [service_plan]) }
    let(:order_item) do
      create(
        :order_item,
        :portfolio_item     => portfolio_item,
        :service_plan_ref   => service_plan_ref,
        :service_parameters => {"name" => "joe", "Totally not a pass" => "s3cret"},
        :process_scope      => 'after'
      )
    end

    context "when there is a valid service_plan_ref" do
      let(:service_plan_ref) { "777" }

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
          }, {
            :name           => "name",
            :label          => "field 1",
            :component      => "textarea-field",
            :helperText     => "That's not my name.",
            :initialValue   => "{{product.artifacts.testk}}",
            :isSubstitution => true
          }]
        end
        let(:result) { subject.process.sanitized_parameters.values }

        context "when portfolio_item has service plans" do
          it "returns 3 masked values and 1 unmasked" do
            expect(result.count { |v| v == described_class::MASKED_VALUE }).to eq(3)
            expect(result.count { |v| v != described_class::MASKED_VALUE }).to eq(1)
          end
        end

        context "when portfilio_item has no service plans" do
          let(:portfolio_item) { create(:portfolio_item) }
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

          it "returns 3 masked values and 1 unmasked" do
            expect(result.count { |v| v == described_class::MASKED_VALUE }).to eq(3)
            expect(result.count { |v| v != described_class::MASKED_VALUE }).to eq(1)
          end
        end
      end
    end

    context "when the service plan ref is 'null'" do
      let(:service_plan_ref) { nil }
      let(:fields) { [] }

      it "does not call the api" do
        subject.process
        expect(a_request(:any, /inventory/)).not_to have_been_made
      end

      it "returns an empty hash" do
        expect(subject.process.sanitized_parameters).to eq({})
      end
    end
  end
end
