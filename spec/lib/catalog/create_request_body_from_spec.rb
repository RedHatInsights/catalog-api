describe Catalog::CreateRequestBodyFrom, :type => [:service, :current_forwardable, :topology, :sources] do
  let(:subject) { described_class.new(order, order_item, task) }
  let(:order) { create(:order) }
  let(:order_item) { create(:order_item_with_callback) }
  let(:task) { TopologicalInventoryApiClient::Task.new }

  describe "#process" do
    let(:sanitize_service_instance) { instance_double(Catalog::OrderItemSanitizedParameters, :sanitized_parameters => {:a => 1}) }
    let(:local_tag_service_instance) { instance_double(Tags::CollectLocalOrderResources, :tag_resources => ["a"]) }
    let(:remote_tag_service_instance) { instance_double(Tags::Topology::RemoteInventory, :tag_resources => ["b"]) }
    let(:source_response) do
      SourcesApiClient::Source.new(:name => 'the platform')
    end

    before do
      allow(Catalog::OrderItemSanitizedParameters).to receive(:new).and_return(sanitize_service_instance)
      allow(sanitize_service_instance).to receive(:process).and_return(sanitize_service_instance)
      allow(Tags::CollectLocalOrderResources).to receive(:new).with(:order_id => order.id).and_return(local_tag_service_instance)
      allow(local_tag_service_instance).to receive(:process).and_return(local_tag_service_instance)
      allow(Tags::Topology::RemoteInventory).to receive(:new).with(task).and_return(remote_tag_service_instance)
      allow(remote_tag_service_instance).to receive(:process).and_return(remote_tag_service_instance)
      allow(remote_tag_service_instance).to receive(:cached_tag_resources).and_return(remote_tag_service_instance.tag_resources)

      stub_request(:get, sources_url("sources/#{order_item.portfolio_item.service_offering_source_ref}"))
        .to_return(:status => 200, :body => source_response.to_json, :headers => default_headers)
    end

    it "stores an ApprovalApiClient::RequestIn object as the result" do
      req = ApprovalApiClient::RequestIn.new.tap do |request|
        request.name = order_item.portfolio_item.name
        request.content = {
          :product   => order_item.portfolio_item.name,
          :portfolio => order_item.portfolio_item.portfolio.name,
          :order_id  => order_item.order_id.to_s,
          :platform  => "the platform",
          :params    => {:a => 1}
        }
        request.tag_resources = ["a", "b"]
      end

      expect(subject.process.result.to_json).to eq(req.to_json)
      expect(subject.process.result.content[:platform]).to eq (source_response.name)
    end
  end
end
