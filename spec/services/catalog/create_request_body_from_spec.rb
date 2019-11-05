describe Catalog::CreateRequestBodyFrom, :type => :service do
  let(:subject) { described_class.new(order, order_item, task) }
  let(:order) { create(:order) }
  let(:order_item) { create(:order_item) }
  let(:task) { TopologicalInventoryApiClient::Task.new }

  describe "#process" do
    let(:sanitize_service_instance) { instance_double(Catalog::OrderItemSanitizedParameters, :sanitized_parameters => {:a => 1}) }
    let(:local_tag_service_instance) { instance_double(Tags::CollectLocalOrderResources, :tag_resources => []) }
    let(:remote_tag_service_instance) { instance_double(Tags::CollectRemoteInventoryResources, :tag_resources => []) }

    before do
      allow(Catalog::OrderItemSanitizedParameters).to receive(:new).and_return(sanitize_service_instance)
      allow(sanitize_service_instance).to receive(:process).and_return(sanitize_service_instance)
      allow(Tags::CollectLocalOrderResources).to receive(:new).with(:order_id => order.id).and_return(local_tag_service_instance)
      allow(local_tag_service_instance).to receive(:process).and_return(local_tag_service_instance)
      allow(Tags::CollectRemoteInventoryResources).to receive(:new).with(task).and_return(remote_tag_service_instance)
      allow(remote_tag_service_instance).to receive(:process).and_return(remote_tag_service_instance)
    end

    it "stores an ApprovalApiClient::RequestIn object as the result" do
      req = ApprovalApiClient::RequestIn.new.tap do |request|
        request.name = order_item.portfolio_item.name
        request.content = {
          :product   => order_item.portfolio_item.name,
          :portfolio => order_item.portfolio_item.portfolio.name,
          :order_id  => order_item.order_id.to_s,
          :params    => {:a => 1}
        }
        request.tag_resources = []
      end

      expect(subject.process.result.to_json).to eq(req.to_json)
    end
  end
end
