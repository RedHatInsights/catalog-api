describe "v1.0 - OrderRequests", :type => [:request, :v1] do
  let!(:order1) { create(:order) }
  let!(:order2) { create(:order) }
  let!(:order3) { create(:order, :owner => 'barney') }

  before do
    allow(Insights::API::Common::RBAC::Access).to receive(:new).and_return(catalog_access)
    allow(catalog_access).to receive(:process).and_return(catalog_access)
  end

  shared_examples_for "#index" do
    it "fetch all allowed orders" do
      get "#{api_version}/orders", :headers => default_headers

      expect(response.content_type).to eq("application/json")
      expect(response).to have_http_status(:ok)
      expect(json['data'].collect { |item| item['id'] }).to match_array(order_ids)
    end
  end

  shared_examples_for "#show" do
    subject { get "#{api_version}/orders/#{order_id}", :headers => default_headers }

    it "fetches a single allowed order" do
      subject

      expect(response.content_type).to eq("application/json")
      expect(response).to have_http_status(:ok)
      expect(json['id']).to eq order_id.to_s
    end

    it_behaves_like "action that tests authorization", :show?, Order
  end

  context "Catalog User" do
    let(:catalog_access) { instance_double(Insights::API::Common::RBAC::Access, :scopes => %w[group]) }
    let(:order_ids) { [order1.id.to_s, order2.id.to_s] }
    let(:ace_entries) { instance_double(Catalog::RBAC::AccessControlEntries) }

    before do
      allow(Catalog::RBAC::AccessControlEntries).to receive(:new).and_return(ace_entries)
      allow(ace_entries).to receive(:ace_ids).with('read', Order).and_return(order_ids)
    end

    context "index" do
      it_behaves_like "#index"
    end

    context "show" do
      let(:order_id) { order1.id }

      it_behaves_like "#show"
    end
  end

  context "Catalog Administrator" do
    let(:catalog_access) { instance_double(Insights::API::Common::RBAC::Access, :scopes => %w[admin]) }
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
