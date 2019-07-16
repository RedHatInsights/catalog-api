describe Internal::V1x0::NotifyController, :type => :request do
  around do |example|
    bypass_rbac do
      example.call
    end
  end

  describe "POST /notify/approval_request/:id" do
    let(:approval_request) { create(:approval_request, :approval_request_ref => "123") }

    it "returns a 200" do
      post "/internal/v1.0/notify/approval_request/123", :headers => default_headers, :params => {:payload => {:decision => "test"}.to_json}

      expect(response.status).to eq(200)
    end
  end

  describe "POST /notify/order_item/:task_id" do
    let(:tenant) { create(:tenant) }
    let(:order) { create(:order, :tenant_id => tenant.id) }
    let(:portfolio_item) { create(:portfolio_item, :service_offering_ref => "123", :tenant_id => tenant.id) }
    let!(:order_item) do
      create(:order_item,
             :order_id          => order.id,
             :portfolio_item_id => portfolio_item.id,
             :tenant_id         => tenant.id,
             :topology_task_ref => "321")
    end
    let(:update_order_item) { instance_double("Catalog::UpdateOrderItem") }

    before do
      allow(Catalog::UpdateOrderItem).to receive(:new).and_return(update_order_item)
      allow(update_order_item).to receive(:process)
    end

    it "returns a 200" do
      post "/internal/v1.0/notify/order_item/321", :headers => default_headers, :params => {:payload => {:status => "test"}, :message => "message"}

      expect(response.status).to eq(200)
    end
  end
end
