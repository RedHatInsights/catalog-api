describe "v1.0 - Portfolios RBAC API", :type => [:request, :v1] do
  let!(:portfolio1) { create(:portfolio) }
  let!(:portfolio2) { create(:portfolio) }
  let(:access_obj) { instance_double(Insights::API::Common::RBAC::Access, :owner_scoped? => false, :accessible? => true) }

  let(:block_access_obj) { instance_double(Insights::API::Common::RBAC::Access, :accessible? => false) }
  let(:params) { {:name => 'Demo', :description => 'Desc 1' } }
  let(:group1) { instance_double(RBACApiClient::GroupOut, :name => 'group1', :uuid => "123") }
  let(:rs_class) { class_double("Insights::API::Common::RBAC::Service").as_stubbed_const(:transfer_nested_constants => true) }
  let(:api_instance) { double }
  let(:principal_options) { {:scope=>"principal"} }
  let(:role_list) { [RBACApiClient::RoleOut.new(:name => "role", :uuid => "123-456")] }

  before do
    allow(rs_class).to receive(:call).with(RBACApiClient::GroupApi).and_yield(api_instance)
    allow(rs_class).to receive(:call).with(RBACApiClient::RoleApi).and_yield(api_instance)
    allow(Insights::API::Common::RBAC::Service).to receive(:paginate).with(api_instance, :list_groups, principal_options).and_return([group1])
    allow(Insights::API::Common::RBAC::Service).to receive(:paginate).with(api_instance, :list_groups, {}).and_return([group1])
    allow(Insights::API::Common::RBAC::Service).to receive(:paginate).with(api_instance, :list_roles, {:name => "Catalog Administrator", :scope => "principal"}).and_return(role_list)
  end

  describe "POST /portfolios/:portfolio_id/copy" do
    context "when the user is a catalog administrator" do
      it 'returns a 200' do
        post "#{api_version}/portfolios/#{portfolio1.id}/copy", :headers => default_headers
        expect(response).to have_http_status(:ok)
      end
    end

    context "when the user is not a catalog administrator" do
      let(:role_list) { [] }

      it 'returns a 403' do
        post "#{api_version}/portfolios/#{portfolio1.id}/copy", :headers => default_headers
        expect(response).to have_http_status(403)
      end
    end
  end

  context "when the permissions array is malformed" do
    it "errors on a blank array" do
      params = {:permissions => [], :group_uuids => ['1'] }
      post "#{api_version}/portfolios/#{portfolio1.id}/share", :headers => default_headers, :params => params

      expect(response).to have_http_status(:bad_request)
      expect(first_error_detail).to match(/contains fewer than min items/)
    end

    it "errors when the object is not an array" do
      params = {:permissions => 1, :group_uuids => ['1'] }
      post "#{api_version}/portfolios/#{portfolio1.id}/share", :headers => default_headers, :params => params

      expect(response).to have_http_status(:bad_request)
      expect(first_error_detail).to match(/expected array, but received Integer/)
    end
  end

  context "when the permissions array is proper" do
    let(:permissions) { ['update'] }
    describe "#share" do
      it "goes through validation" do
        post "#{api_version}/portfolios/#{portfolio1.id}/share", :headers => default_headers, :params => {
          :permissions => permissions,
          :group_uuids => [group1.uuid]
        }
        expect(response).to have_http_status(:no_content)
      end
    end

    describe "#unshare" do
      it "goes through validation" do
        create(:access_control_entry, :has_update_permission, :group_uuid => group1.uuid, :aceable => portfolio1)
        post "#{api_version}/portfolios/#{portfolio1.id}/unshare", :headers => default_headers, :params => {
          :permissions => permissions,
          :group_uuids => [group1.uuid]
        }

        expect(response).to have_http_status(:no_content)
      end
    end
  end
end
