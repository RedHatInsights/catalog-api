describe "OrderRequests", :type => :request do
  let!(:order1) { create(:order) }
  let!(:order2) { create(:order) }
  let!(:order3) { create(:order, :owner => 'barney') }
  let(:user_access_obj) { instance_double(RBAC::Access, :owner_scoped? => true, :accessible? => true) }
  let(:admin_access_obj) { instance_double(RBAC::Access, :owner_scoped? => false, :accessible? => true, :id_list => []) }

  shared_examples_for "#index" do
    it "fetch all allowed orders" do
      allow(RBAC::Access).to receive(:new).with('orders', 'read').and_return(access_obj)
      allow(access_obj).to receive(:process).and_return(access_obj)
      get "/api/v1.0/orders", :headers => default_headers

      expect(response.content_type).to eq("application/json")
      expect(response).to have_http_status(:ok)
      expect(json['data'].collect { |item| item['id'] }).to match_array(order_ids)
    end
  end

  context "Catalog User" do
    let(:access_obj) { user_access_obj }
    let(:order_ids) { [order1.id.to_s, order2.id.to_s] }
    it_behaves_like "#index"
  end

  context "Catalog Administrator" do
    let(:access_obj) { admin_access_obj }
    let(:order_ids) { [order1.id.to_s, order2.id.to_s, order3.id.to_s] }
    it_behaves_like "#index"
  end
end
