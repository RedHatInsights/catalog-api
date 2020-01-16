describe 'Portfolios Delete Access RBAC API', :type => [:request, :v1] do
  let!(:portfolio1) { create(:portfolio) }
  let!(:portfolio2) { create(:portfolio) }
  let(:access_obj) { instance_double(Insights::API::Common::RBAC::Access, :accessible? => true) }
  let(:block_access_obj) { instance_double(Insights::API::Common::RBAC::Access, :accessible? => false) }
  let(:group1) { instance_double(RBACApiClient::GroupOut, :name => 'group1', :uuid => "123") }
  let(:permission) { 'delete' }
  let(:rs_class) { class_double("Insights::API::Common::RBAC::Service").as_stubbed_const(:transfer_nested_constants => true) }
  let(:api_instance) { double }
  let(:list_group_options) { {:scope=>"principal"} }

  describe "DELETE /portfolios" do
    before do
      allow(rs_class).to receive(:call).with(RBACApiClient::GroupApi).and_yield(api_instance)
      allow(Insights::API::Common::RBAC::Service).to receive(:paginate).with(api_instance, :list_groups, list_group_options).and_return([group1])
    end

    context "Catalog User has delete permission" do
      before do
        allow(Insights::API::Common::RBAC::Access).to receive(:new).with('portfolios', permission).and_return(access_obj)
        allow(Insights::API::Common::RBAC::Roles).to receive(:assigned_role?).with(catalog_admin_role).and_return(false)
        allow(access_obj).to receive(:process).and_return(access_obj)
        create(:access_control_entry, :has_delete_permission, :group_uuid => group1.uuid, :aceable => portfolio1)
      end

      it 'only allows deleting a specific portfolio' do
        delete "#{api_version}/portfolios/#{portfolio1.id}", :headers => default_headers
        expect(response).to have_http_status(:ok)
      end

      it 'fails deleting another portfolio' do
        delete "#{api_version}/portfolios/#{portfolio2.id}", :headers => default_headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "Catalog User does not have delete permission" do
      before do
        allow(Insights::API::Common::RBAC::Access).to receive(:new).with('portfolios', permission).and_return(block_access_obj)
        allow(Insights::API::Common::RBAC::Roles).to receive(:assigned_role?).with(catalog_admin_role).and_return(false)
        allow(block_access_obj).to receive(:process).and_return(block_access_obj)
      end

      it 'fails deleting any portfolio' do
        delete "#{api_version}/portfolios/#{portfolio1.id}", :headers => default_headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "Catalog Administrator has delete permission by default" do
      before do
        allow(Insights::API::Common::RBAC::Roles).to receive(:assigned_role?).with(catalog_admin_role).and_return(true)
      end

      it 'successfully deletes a portfolio' do
        delete "#{api_version}/portfolios/#{portfolio1.id}", :headers => default_headers
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
