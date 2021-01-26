describe Api::V1x1::Catalog::PortfolioItemOrderable, :type => [:service, :current_forwardable, :inventory, :sources] do
  let(:subject) { described_class.new(portfolio_item) }
  let(:service_offering_ref) { '998' }
  let(:service_offering_source_ref) { '999' }
  let(:archived_at) { nil }
  let(:availability_status) { 'available' }
  let(:survey_changed) { false }
  let(:portfolio_item) do
    create(:portfolio_item,
           :service_offering_ref        => service_offering_ref,
           :service_offering_source_ref => service_offering_source_ref)
  end
  let(:service_plans) { [] }

  let(:service_offering_response) do
    CatalogInventoryApiClient::ServiceOffering.new(:archived_at => archived_at)
  end

  let(:source_response) do
    SourcesApiClient::Source.new(:name => 'the platform', :availability_status => availability_status)
  end

  describe "#process" do
    context "no errors" do
      before do
        stub_request(:get, inventory_url("service_offerings/#{service_offering_ref}"))
          .to_return(:status => 200, :body => service_offering_response.to_json, :headers => default_headers)
        stub_request(:get, sources_url("sources/#{service_offering_source_ref}"))
          .to_return(:status => 200, :body => source_response.to_json, :headers => default_headers)
        allow(::Catalog::SurveyCompare).to receive(:any_changed?).with(service_plans).and_return(survey_changed)
      end

      context "when the nothing has changed without service plans" do
        it "returns true" do
          expect(subject.process.result).to be(true)
        end
      end

      context "when the nothing has changed with service plans" do
        let(:service_plans) { [create(:service_plan, :portfolio_item => portfolio_item)] }
        it "returns true" do
          expect(subject.process.result).to be(true)
        end
      end

      context "when the source is not available" do
        let(:availability_status) { 'not available' }
        it "returns false" do
          expect(subject.process.result).to be(false)
        end
      end

      context "when the survey has changed" do
        let(:survey_changed) { true }
        it "returns false" do
          expect(subject.process.result).to be(false)
        end
      end

      context "when the service offering has been archived" do
        let(:archived_at) { Time.now }
        it "returns false" do
          expect(subject.process.result).to be(false)
        end
      end
    end

    context "with errors from inventory" do
      before do
        stub_request(:get, inventory_url("service_offerings/#{service_offering_ref}"))
          .to_raise(Catalog::InventoryError.new("Kaboom"))
        stub_request(:get, sources_url("sources/#{service_offering_source_ref}"))
          .to_return(:status => 200, :body => source_response.to_json, :headers => default_headers)
      end

      context "when the service offering cannot be retrieved" do
        it "returns false" do
          obj = subject.process
          expect(obj.result).to be(false)
          expect(obj.messages[0]).to match(/Service offering could not be retrieved/)
        end
      end
    end

    context "with errors from source" do
      before do
        stub_request(:get, inventory_url("service_offerings/#{service_offering_ref}"))
          .to_return(:status => 200, :body => service_offering_response.to_json, :headers => default_headers)
        stub_request(:get, sources_url("sources/#{service_offering_source_ref}"))
          .to_raise(Catalog::SourcesError.new("Kaboom"))
      end

      context "when the source cannot be retrieved" do
        it "returns false" do
          obj = subject.process
          expect(obj.result).to be(false)
          expect(obj.messages[0]).to match(/Source could not be retrieved/)
        end
      end
    end
  end
end
