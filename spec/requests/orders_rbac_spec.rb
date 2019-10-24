describe "OrderRequests", :type => :request do
  let!(:order1) { create(:order) }
  let!(:order2) { create(:order) }
  let!(:order3) { create(:order, :owner => 'barney') }
  let(:is_admin) { false }
  let(:access_obj) { nil }
  let(:user_access_obj) { instance_double(ManageIQ::API::Common::RBAC::Access, :owner_scoped? => true, :accessible? => true) }

  shared_examples_for "#index" do
    it "fetch all allowed orders" do
      allow(ManageIQ::API::Common::RBAC::Roles).to receive(:assigned_role?).with(catalog_admin_role).and_return(is_admin)
      if access_obj
        allow(ManageIQ::API::Common::RBAC::Access).to receive(:new).with('orders', 'read').and_return(access_obj)
        allow(access_obj).to receive(:process).and_return(access_obj)
      end
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
    let(:is_admin) { true }
    let(:order_ids) { [order1.id.to_s, order2.id.to_s, order3.id.to_s] }
    it_behaves_like "#index"
  end
end
