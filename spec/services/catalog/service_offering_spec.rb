describe Catalog::ServiceOffering do
  let(:subject) { described_class.new(order_item.order.id) }

  before do
    allow(Insights::API::Common::Request).to receive(:current_forwardable).and_return(default_headers)
  end

  around do |example|
    with_modified_env(:TOPOLOGICAL_INVENTORY_URL => "http://topology") do
      example.call
    end
  end

  describe "#process" do
    let!(:order_item) { create(:order_item, :portfolio_item => portfolio_item) }
    let(:portfolio_item) { create(:portfolio_item, :service_offering_ref => 123) }
    let(:service_offering_response) { TopologicalInventoryApiClient::ServiceOffering.new(:archived_at => archived_at) }

    before do
      stub_request(:get, "http://topology/api/topological-inventory/v2.0/service_offerings/123")
        .to_return(:status => 200, :body => service_offering_response.to_json, :headers => default_headers)
    end

    context "when archived_at is present" do
      let(:archived_at) { Time.current }

      it "sets archived to true" do
        expect(subject.process.archived).to be(true)
      end

      it "exposes order" do
        expect(subject.process.order).to eq(order_item.order)
      end
    end

    context "when archived_at is not present" do
      let(:archived_at) { nil }

      it "sets archived to false" do
        expect(subject.process.archived).to be(false)
      end

      it "exposes order" do
        expect(subject.process.order).to eq(order_item.order)
      end
    end
  end
end
