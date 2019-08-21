describe Catalog::ValidateSource do
  let(:tenant) { create(:tenant) }
  let(:portfolio_item) { create(:portfolio_item, :tenant_id => tenant.id, :service_offering_source_ref => "17") }
  let(:response_headers) { {"Content-Type" => 'application/json'} }

  let(:validate_source) { described_class.new(portfolio_item.id).process }

  around do |example|
    with_modified_env(:SOURCES_URL => "http://localhost") do
      ManageIQ::API::Common::Request.with_request(default_request) { example.call }
    end
  end

  before do
    stub_request(:get, "http://localhost/api/sources/v1.0/application_types")
      .to_return(:status => 200, :body => response.to_json, :headers => response_headers)
  end

  describe "#process" do
    context "when the application_types include the source id" do
      let(:response) { {:data => [{:id => 1}, {:id => 17}]} }

      it "sets the valid instance var to true" do
        expect(validate_source.valid).to eq true
      end
    end

    context "when the application_types include the source id" do
      let(:response) { {:data => [{:id => 1}]} }

      it "sets the valid instance var to false" do
        expect(validate_source.valid).to eq false
      end
    end
  end
end
