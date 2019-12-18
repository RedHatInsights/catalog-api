describe "v1.0 - OrderRequests", :type => :request do
  let(:api_version) { api(1.0) }
  let!(:order1) { create(:order) }
  let!(:order2) { create(:order) }
  let!(:order3) { create(:order, :owner => 'barney') }
  let(:is_admin) { false }
  let(:access_obj) { nil }
  let(:user_access_obj) { instance_double(Insights::API::Common::RBAC::Access, :owner_scoped? => true, :accessible? => true) }

  let(:group1) { instance_double(RBACApiClient::GroupOut, :name => 'group1', :uuid => "123") }
  let(:rs_class) { class_double("Insights::API::Common::RBAC::Service").as_stubbed_const(:transfer_nested_constants => true) }
  let(:api_instance) { double }
  let(:principal_options) { {:scope=>"principal"} }

  before do
    allow(rs_class).to receive(:call).with(RBACApiClient::GroupApi).and_yield(api_instance)
    allow(Insights::API::Common::RBAC::Service).to receive(:paginate).with(api_instance, :list_groups, principal_options).and_return([group1])
    allow(Insights::API::Common::RBAC::Service).to receive(:paginate).with(api_instance, :list_groups, {}).and_return([group1])
  end
  shared_examples_for "#index" do
    it "fetch all allowed orders" do
      allow(Insights::API::Common::RBAC::Roles).to receive(:assigned_role?).with(catalog_admin_role).and_return(is_admin)
      if access_obj
        allow(Insights::API::Common::RBAC::Access).to receive(:new).with('orders', 'read').and_return(access_obj)
        allow(access_obj).to receive(:process).and_return(access_obj)
      end
      get "/#{api_version}/orders", :headers => default_headers

      expect(response.content_type).to eq("application/json")
      expect(response).to have_http_status(:ok)
      expect(json['data'].collect { |item| item['id'] }).to match_array(order_ids)
    end
  end

  shared_examples_for "#show" do
    it "fetches a single allowed order" do
      allow(Insights::API::Common::RBAC::Roles).to receive(:assigned_role?).with(catalog_admin_role).and_return(is_admin)

      if access_obj
        allow(Insights::API::Common::RBAC::Access).to receive(:new).with('orders', 'read').and_return(access_obj)
        allow(access_obj).to receive(:process).and_return(access_obj)
      end
      get "/#{api_version}/orders/#{order_id}", :headers => default_headers

      expect(response.content_type).to eq("application/json")
      expect(response).to have_http_status(:ok)
      expect(json['id']).to eq order_id.to_s
    end
  end

  context "Catalog User" do
    let(:access_obj) { user_access_obj }
    let(:order_ids) { [order1.id.to_s, order2.id.to_s] }
    context "index" do
      it_behaves_like "#index"
    end

    context "show" do
      let(:order_id) { order1.id }
      it_behaves_like "#show"
    end
  end

  context "Catalog Administrator" do
    let(:is_admin) { true }
    let(:order_ids) { [order1.id.to_s, order2.id.to_s, order3.id.to_s] }
    context "index" do
      it_behaves_like "#index"
    end

    context "show" do
      let(:order_id) { order1.id }
      it_behaves_like "#show"
    end
  end
end
