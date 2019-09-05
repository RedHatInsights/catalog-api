describe Internal::V1x0::NotifyController, :type => :request do
  around do |example|
    bypass_rbac do
      example.call
    end
  end

  describe "POST /notify/approval_request/:id" do
    let(:tenant) { create(:tenant) }
    let(:order) { create(:order, :tenant_id => tenant.id) }
    let(:portfolio) { create(:portfolio, :tenant_id => tenant.id) }
    let(:portfolio_item) { create(:portfolio_item, :tenant_id => tenant.id, :portfolio => portfolio) }
    let(:order_item) { create(:order_item, :order_id => order.id, :portfolio_item_id => portfolio_item.id, :tenant_id => tenant.id, :context => default_request) }
    let!(:approval_request) { create(:approval_request, :order_item_id => order_item.id, :approval_request_ref => "123", :tenant_id => tenant.id) }
    let(:approval_transition) { instance_double("Catalog::UpdateOrderItem") }

    before do
      allow(Catalog::ApprovalTransition).to receive(:new).and_return(approval_transition)
      allow(approval_transition).to receive(:process)
    end

    it "returns a 200" do
      post "/internal/v1.0/notify/approval_request/123", :headers => default_headers, :params => {:payload => {:decision => "approved", :request_id => "123"}, :message => "request_finished"}
      expect(response.status).to eq(200)
    end
  end

  describe "POST /notify/order_item/:task_id" do
    let(:tenant) { create(:tenant) }
    let(:order) { create(:order, :tenant_id => tenant.id) }
    let(:portfolio) { create(:portfolio, :tenant_id => tenant.id) }
    let(:portfolio_item) { create(:portfolio_item, :portfolio => portfolio, :service_offering_ref => "123", :tenant_id => tenant.id) }
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
