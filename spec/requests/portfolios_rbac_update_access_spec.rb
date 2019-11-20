describe 'Portfolios Write Access RBAC API' do
  let!(:portfolio1) { create(:portfolio) }
  let!(:portfolio2) { create(:portfolio) }
  let(:access_obj) { instance_double(Insights::API::Common::RBAC::Access, :accessible? => true, :id_list => id_list) }
  let(:valid_attributes) { {:name => 'Fred', :description => "Fred's Portfolio" } }
  let(:updated_attributes) { {:name => 'Barney', :description => "Barney's Portfolio" } }
  let(:id_list) { [] }
  let(:block_access_obj) { instance_double(Insights::API::Common::RBAC::Access, :accessible? => false) }

  describe "POST /portfolios" do
    it 'creates a portfolio' do
      allow(Insights::API::Common::RBAC::Roles).to receive(:assigned_role?).with(catalog_admin_role).and_return(false)
      allow(Insights::API::Common::RBAC::Access).to receive(:new).with('portfolios', 'update').and_return(access_obj)
      allow(Insights::API::Common::RBAC::Access).to receive(:new).with('portfolios', 'create').and_return(access_obj)
      allow(access_obj).to receive(:process).and_return(access_obj)
      post "#{api('1.0')}/portfolios", :headers => default_headers, :params => valid_attributes

      expect(response).to have_http_status(:ok)
    end

    it 'returns status code 403' do
      allow(Insights::API::Common::RBAC::Access).to receive(:new).with('portfolios', 'update').and_return(block_access_obj)
      allow(Insights::API::Common::RBAC::Roles).to receive(:assigned_role?).with(catalog_admin_role).and_return(false)
      allow(Insights::API::Common::RBAC::Access).to receive(:new).with('portfolios', 'create').and_return(block_access_obj)
      allow(block_access_obj).to receive(:process).and_return(block_access_obj)
      post "#{api('1.0')}/portfolios", :headers => default_headers, :params => valid_attributes

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "PATCH /portfolios" do
    let(:id_list) { [portfolio1.id.to_s] }

    before do
      allow(Insights::API::Common::RBAC::Access).to receive(:new).with('portfolios', 'update').and_return(access_obj)
      allow(Insights::API::Common::RBAC::Access).to receive(:new).with('portfolios', 'create').and_return(access_obj)
      allow(Insights::API::Common::RBAC::Roles).to receive(:assigned_role?).with(catalog_admin_role).and_return(false)
      allow(access_obj).to receive(:process).and_return(access_obj)
    end

    it 'only allows updating a specific portfolio' do
      patch "#{api('1.0')}/portfolios/#{portfolio1.id}", :headers => default_headers, :params => updated_attributes
      expect(response).to have_http_status(:ok)
    end

    it 'fails updating a portfolio' do
      patch "#{api('1.0')}/portfolios/#{portfolio2.id}", :headers => default_headers, :params => updated_attributes
      expect(response).to have_http_status(:forbidden)
    end
  end
end
