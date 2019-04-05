describe "ProgressMessageRequests", :type => :request do
  around do |example|
    bypass_rbac do
      example.call
    end
  end

  let(:tenant) { create(:tenant, :external_tenant => default_user_hash['identity']['account_number']) }
  let(:order) { create(:order, :tenant_id => tenant.id) }
  let!(:order_item) { create(:order_item, :order_id => order.id, :portfolio_item_id => portfolio_item.id, :tenant_id => tenant.id) }
  let(:portfolio_item) { create(:portfolio_item, :service_offering_ref => "123", :tenant_id => tenant.id) }
  let!(:progress_message) { create(:progress_message, :order_item_id => order_item.id.to_s, :tenant_id => tenant.id) }

  context "v1.0" do
    it "lists progress messages" do
      get "/#{api}/order_items/#{order_item.id}/progress_messages", :headers => default_headers

      expect(response.content_type).to eq("application/json")
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['data'].first['id']).to eq(progress_message.id.to_s)
    end
  end
end
