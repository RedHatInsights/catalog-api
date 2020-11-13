describe Catalog::OrderItemRuntimeParameters, :type => [:service, :topology, :current_forwardable] do
  let(:subject) { described_class.new(order_item) }

  describe "#process" do
    let(:service_plan) { create(:service_plan, :base => {:schema => {:fields => fields}}, :modified => nil) }
    let(:item_name) { "s.t $ ./ \b } 中文{ |" }
    let(:portfolio_item) { create(:portfolio_item, :name => item_name, :service_plans => [service_plan]) }
    let(:order_item) do
      create(
        :order_item,
        :name               => item_name,
        :portfolio_item     => portfolio_item,
        :service_plan_ref   => service_plan_ref,
        :artifacts          => artifacts,
        :service_parameters => {"name" => "{{after.#{item_name}.artifacts.testk}}", "Totally not a pass" => "s3cret"},
        :process_scope      => 'after'
      )
    end
    let(:artifacts) { {'testk' => 'testv'} }
    let(:data_type) { 'string' }

    context "when there is a valid service_plan_ref" do
      around do |example|
        Insights::API::Common::Request.with_request(default_request) { example.call }
      end

      let(:service_plan_ref) { "777" }
      let(:result) { subject.process.runtime_parameters.values }
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
          :type           => data_type,
          :label          => "field 1",
          :component      => "textarea-field",
          :helperText     => "That's not my name.",
          :initialValue   => "{{product.artifacts.testk}}",
          :isSubstitution => true
        }]
      end

      context 'when substitution data type is string' do
        it 'includes a string in the parameters' do
          expect(result).to match_array %w[testv s3cret]
        end
      end

      context 'when substitution data type is integer' do
        let(:data_type) { 'integer' }

        context 'when substituted string is a valid integer' do
          let(:artifacts) { {'testk' => 500} }

          it 'includes an integer in the parameters' do
            expect(result).to match_array [500, 's3cret']
          end
        end

        context 'when substituted string is not a valid integer' do
          let(:artifacts) { {'testk' => true} }

          it 'raise an error' do
            expect { result }.to raise_error(ArgumentError)
          end
        end
      end

      context 'when substitution data type is float' do
        let(:data_type) { 'float' }

        context 'when substituted string is a valid float' do
          let(:artifacts) { {'testk' => '50.20'} }

          it 'includes a floating number in the parameters' do
            expect(result).to match_array [50.20, 's3cret']
          end
        end

        context 'when substituted string is not a valid float' do
          let(:artifacts) { {'testk' => 'any'} }

          it 'raise an error' do
            expect { result }.to raise_error(ArgumentError)
          end
        end
      end

      context 'when substitution data type is boolean' do
        let(:data_type) { 'boolean' }

        context 'when substituted string is a valid boolean' do
          let(:artifacts) { {'testk' => 'false'} }

          it 'includes a boolean in the parameters' do
            expect(result).to match_array [false, 's3cret']
          end
        end

        context 'when substituted string is not a valid boolean' do
          let(:artifacts) { {'testk' => 'any'} }

          it 'raise an error' do
            expect { result }.to raise_error(ArgumentError)
          end
        end
      end

      context 'when substitution key does not exist' do
        let(:artifacts) { {} }

        it 'includes an empty string in the parameters' do
          expect(Rails.logger).to receive(:warn)
          expect(result).to match_array ['', 's3cret']
        end
      end

      context "when service_parameters is nil" do
        let(:order_item) { create(:order_item, :service_parameters => nil, :portfolio_item => portfolio_item, :service_plan_ref => service_plan_ref) }

        it "returns empty filtered parameters" do
          expect(subject.process.runtime_parameters).to be_empty
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
        expect(subject.process.runtime_parameters).to eq({})
      end
    end
  end
end
