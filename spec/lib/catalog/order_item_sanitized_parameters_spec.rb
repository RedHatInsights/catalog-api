describe Catalog::OrderItemSanitizedParameters, :type => [:service, :topology, :current_forwardable] do
  let(:subject) { described_class.new(params) }
  let(:params) { ActionController::Parameters.new('order_item_id' => order_item.id) }

  describe "#process" do
    let(:order_item) { create(:order_item_with_callback, :service_plan_ref => service_plan_ref, :service_parameters => {"name" => "fred", "Totally not a pass" => "s3cret"}) }

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
        stub_request(:get, topological_url("service_plans/777"))
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
          }, {
            :name         => "name",
            :label        => "field 1",
            :component    => "textarea-field",
            :helperText   => "That's not my name.",
            :initialValue => ""
          }]
        end
        let(:result) { subject.process.sanitized_parameters.values }

        context "when the api call is successful" do
          it "returns 3 masked values" do
            expect(result.count { |v| v == described_class::MASKED_VALUE }).to eq 3
          end

          it "leaves one value alone" do
            expect(result.count { |v| v != described_class::MASKED_VALUE }).to eq 1
          end
        end

        context "when the api call is not successful" do
          before do
            stub_request(:get, topological_url("service_plans/777"))
              .to_raise(TopologicalInventoryApiClient::ApiError)
          end

          it "handles the exception and reraises a StandardError" do
            expect(Rails.logger).to receive(:error).thrice
            expect { subject.process }.to raise_error(StandardError)
          end
        end

        context "when the do_not_mask_values parameter is set" do
          around do |example|
            Insights::API::Common::Request.with_request(default_request) { example.call }
          end
          let(:item_name) { "s.t $ ./ \b } 中文{ |" }
          let(:portfolio_item) { create(:portfolio_item, :name => item_name) }

          let(:order_item) do
            create(
              :order_item_with_callback,
              :portfolio_item     => portfolio_item,
              :service_plan_ref   => service_plan_ref,
              :service_parameters => {"name" => "{{applicable.#{item_name}.artifacts.testk}}", "Totally not a pass" => "s3cret"},
              :artifacts          => {"testk" => "testv"},
              :process_scope      => 'applicable'
            )
          end
          let(:params) { ActionController::Parameters.new(:order_item => order_item, :do_not_mask_values => true) }

          it "returns only what is in the parameters" do
            expect(result).to match_array %w[testv s3cret]
          end
        end

        context "when raw service parameters is nil" do
          let(:order_item) { create(:order_item, :service_plan_ref => service_plan_ref) }
          let(:params) { ActionController::Parameters.new(:order_item => order_item, :do_not_mask_values => true) }

          it "returns empty filtered parameters" do
            expect(subject.process.sanitized_parameters).to be_empty
          end
        end
      end
    end

    context "when the service plan ref is 'null'" do
      let(:service_plan_ref) { nil }
      let(:fields) { [] }

      it "does not call the api" do
        subject.process
        expect(a_request(:any, /topology/)).not_to have_been_made
      end

      it "returns an empty hash" do
        expect(subject.process.sanitized_parameters).to eq({})
      end
    end
  end
end
