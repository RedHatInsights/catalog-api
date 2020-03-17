describe "v1.0 - Portfolios Write Access RBAC API", :type => [:request, :v1] do
  describe "POST /portfolios" do
    let(:valid_attributes) { {:name => 'Fred', :description => "Fred's Portfolio" } }

    context "when the user is a catalog administrator" do
      before do
        allow(Insights::API::Common::RBAC::Roles).to receive(:assigned_role?).with(catalog_admin_role).and_return(true)
      end

      it 'creates a portfolio' do
        post "#{api_version}/portfolios", :headers => default_headers, :params => valid_attributes

        expect(response).to have_http_status(:ok)
      end
    end

    context "when the user is not a catalog administrator" do
      before do
        allow(Insights::API::Common::RBAC::Roles).to receive(:assigned_role?).with(catalog_admin_role).and_return(false)
      end

      it 'returns status code 403' do
        post "#{api_version}/portfolios", :headers => default_headers, :params => valid_attributes

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "PATCH /portfolios" do
    let!(:portfolio1) { create(:portfolio) }
    let!(:portfolio2) { create(:portfolio) }
    let(:access_obj) { instance_double(Insights::API::Common::RBAC::Access, :accessible? => true) }
    let(:updated_attributes) { {:name => 'Barney', :description => "Barney's Portfolio" } }
    let(:group1) { instance_double(RBACApiClient::GroupOut, :name => 'group1', :uuid => "123") }
    let(:rs_class) { class_double("Insights::API::Common::RBAC::Service").as_stubbed_const(:transfer_nested_constants => true) }
    let(:api_instance) { double }
    let(:list_group_options) { {:scope=>"principal"} }

    before do
      allow(Insights::API::Common::RBAC::Access).to receive(:new).with('portfolios', 'read').and_return(access_obj)
      allow(Insights::API::Common::RBAC::Roles).to receive(:assigned_role?).with(catalog_admin_role).and_return(false)
      allow(access_obj).to receive(:process).and_return(access_obj)
      allow(rs_class).to receive(:call).with(RBACApiClient::GroupApi).and_yield(api_instance)
      allow(Insights::API::Common::RBAC::Service).to receive(:paginate).with(api_instance, :list_groups, list_group_options).and_return([group1])
    end

    context "user has update permission" do
      before do
        allow(Insights::API::Common::RBAC::Access).to receive(:new).with('portfolios', 'update').and_return(access_obj)
        create(:access_control_entry, :has_update_permission, :group_uuid => group1.uuid, :aceable => portfolio1)
      end

      it 'only allows updating a specific portfolio' do
        patch "#{api_version}/portfolios/#{portfolio1.id}", :headers => default_headers, :params => updated_attributes
        expect(response).to have_http_status(:ok)
      end

      it 'fails updating a portfolio' do
        patch "#{api_version}/portfolios/#{portfolio2.id}", :headers => default_headers, :params => updated_attributes
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "user has read only permission for a specific portfolio" do
      before do
        allow(Insights::API::Common::RBAC::Access).to receive(:new).with('portfolios', 'update').and_return(access_obj)
        create(:access_control_entry, :has_read_permission, :group_uuid => group1.uuid, :aceable => portfolio1)
      end

      it 'fails updating a portfolio' do
        patch "#{api_version}/portfolios/#{portfolio1.id}", :headers => default_headers, :params => updated_attributes
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
