describe 'Portfolios RBAC API' do
  let!(:portfolio1) { create(:portfolio) }
  let!(:portfolio2) { create(:portfolio) }
  let(:access_obj) { instance_double(ManageIQ::API::Common::RBAC::Access, :owner_scoped? => false, :accessible? => true, :id_list => [portfolio1.id.to_s]) }
  let(:double_access_obj) { instance_double(ManageIQ::API::Common::RBAC::Access, :owner_scoped? => false, :accessible? => true, :id_list => [portfolio1.id.to_s, portfolio2.id.to_s]) }

  let(:block_access_obj) { instance_double(ManageIQ::API::Common::RBAC::Access, :accessible? => false) }
  let(:share_resource) { instance_double(ManageIQ::API::Common::RBAC::ShareResource) }
  let(:unshare_resource) { instance_double(ManageIQ::API::Common::RBAC::UnshareResource) }
  let(:params) { {:name => 'Demo', :description => 'Desc 1' } }

  describe "POST /portfolios" do
    it "success" do
      allow(ManageIQ::API::Common::RBAC::Access).to receive(:new).with('portfolios', 'create').and_return(access_obj)
      allow(access_obj).to receive(:process).and_return(access_obj)
      post "#{api('1.0')}/portfolios", :headers => default_headers, :params => params
      expect(response).to have_http_status(200)
    end

    it "unauthorized" do
      allow(ManageIQ::API::Common::RBAC::Access).to receive(:new).with('portfolios', 'create').and_return(block_access_obj)
      allow(block_access_obj).to receive(:process).and_return(block_access_obj)
      post "#{api('1.0')}/portfolios", :headers => default_headers, :params => params
      expect(response).to have_http_status(403)
    end
  end

  describe "DELETE /portfolios/{id}" do
    it "success" do
      allow(ManageIQ::API::Common::RBAC::Access).to receive(:new).with('portfolios', 'delete').and_return(access_obj)
      allow(access_obj).to receive(:process).and_return(access_obj)
      delete "#{api("1.0")}/portfolios/#{portfolio1.id}", :headers => default_headers
      expect(response).to have_http_status(200)
    end

    it "unauthorized" do
      allow(ManageIQ::API::Common::RBAC::Access).to receive(:new).with('portfolios', 'delete').and_return(block_access_obj)
      allow(block_access_obj).to receive(:process).and_return(block_access_obj)
      delete "#{api("1.0")}/portfolios/#{portfolio1.id}", :headers => default_headers
      expect(response).to have_http_status(403)
    end
  end

  describe "GET /portfolios" do
    before do
      allow(ManageIQ::API::Common::RBAC::Roles).to receive(:assigned_role?).with(catalog_admin_role).and_return(false)
    end
    it 'returns status code 200' do
      allow(ManageIQ::API::Common::RBAC::Access).to receive(:new).with('portfolios', 'read').and_return(access_obj)
      allow(access_obj).to receive(:process).and_return(access_obj)
      get "#{api('1.0')}/portfolios", :headers => default_headers

      expect(response).to have_http_status(200)
      result = JSON.parse(response.body)
      expect(result['data'][0]['id']).to eq(portfolio1.id.to_s)
    end

    it 'returns status code 403' do
      allow(ManageIQ::API::Common::RBAC::Access).to receive(:new).with('portfolios', 'read').and_return(block_access_obj)
      allow(block_access_obj).to receive(:process).and_return(block_access_obj)
      get "#{api('1.0')}/portfolios", :headers => default_headers

      expect(response).to have_http_status(403)
    end

    context "with filtering" do
      before do
        allow(ManageIQ::API::Common::RBAC::Access).to receive(:new).with('portfolios', 'read').and_return(double_access_obj)
        allow(double_access_obj).to receive(:process).and_return(double_access_obj)
        get "#{api('1.0')}/portfolios?filter[name]=#{portfolio1.name}", :headers => default_headers
      end

      it 'returns a 200' do
        expect(response).to have_http_status(200)
      end

      it 'only returns the portfolio we filtered for' do
        result = JSON.parse(response.body)

        expect(result['meta']['count']).to eq 1
        expect(result['data'][0]['name']).to eq(portfolio1.name)
      end
    end

    context "when user does not have RBAC update portfolios access" do
      before do
        allow(ManageIQ::API::Common::RBAC::Access).to receive(:new).with('portfolios', 'read').and_return(access_obj)
        allow(ManageIQ::API::Common::RBAC::Access).to receive(:new).with('portfolios', 'create').and_return(access_obj)
        allow(access_obj).to receive(:process).and_return(access_obj)

        allow(ManageIQ::API::Common::RBAC::Access).to receive(:new).with('portfolios', 'update').and_return(block_access_obj)
        allow(block_access_obj).to receive(:process).and_return(block_access_obj)
      end

      it 'returns a 403' do
        post "#{api("1.0")}/portfolios/#{portfolio1.id}/copy", :headers => default_headers
        expect(response).to have_http_status(403)
      end
    end

    context "when user has RBAC update portfolios access" do
      let(:portfolio_access_obj) { instance_double(ManageIQ::API::Common::RBAC::Access, :accessible? => true, :owner_scoped? => true, :id_list => [portfolio1.id.to_s]) }
      before do
        allow(ManageIQ::API::Common::RBAC::Access).to receive(:new).with('portfolios', 'read').and_return(access_obj)
        allow(ManageIQ::API::Common::RBAC::Access).to receive(:new).with('portfolios', 'create').and_return(access_obj)
        allow(access_obj).to receive(:process).and_return(access_obj)

        allow(ManageIQ::API::Common::RBAC::Access).to receive(:new).with('portfolios', 'update').and_return(portfolio_access_obj)
        allow(portfolio_access_obj).to receive(:process).and_return(portfolio_access_obj)
      end

      it 'returns a 200' do
        post "#{api("1.0")}/portfolios/#{portfolio1.id}/copy", :headers => default_headers
        expect(response).to have_http_status(:ok)
      end
    end
  end

  context "when the permissions array is malformed" do
    it "errors on a blank array" do
      params = {:permissions => [], :group_uuids => ['1'] }
      post "#{api}/portfolios/#{portfolio1.id}/share", :headers => default_headers, :params => params

      expect(response).to have_http_status(:bad_request)
      expect(first_error_detail).to match(/contains fewer than min items/)
    end

    it "errors when the object is not an array" do
      params = {:permissions => 1, :group_uuids => ['1'] }
      post "#{api}/portfolios/#{portfolio1.id}/share", :headers => default_headers, :params => params

      expect(response).to have_http_status(:bad_request)
      expect(first_error_detail).to match(/expected array, but received Integer/)
    end
  end

  context "when the permissions array is proper" do
    before do
      allow(ManageIQ::API::Common::RBAC::ShareResource).to receive(:new).and_return(share_resource)
      allow(ManageIQ::API::Common::RBAC::UnshareResource).to receive(:new).and_return(unshare_resource)
      allow(share_resource).to receive(:process).and_return(share_resource)
      allow(unshare_resource).to receive(:process).and_return(unshare_resource)
    end

    describe "#share" do
      it "goes through validation" do
        permissions = ["catalog:portfolios:update"]
        post "#{api}/portfolios/#{portfolio1.id}/share", :headers => default_headers, :params => {
          :permissions => permissions,
          :group_uuids => %w[1]
        }

        expect(response).to have_http_status(:no_content)
      end
    end

    describe "#unshare" do
      it "goes through validation" do
        permissions = ["catalog:portfolios:update"]
        post "#{api}/portfolios/#{portfolio1.id}/unshare", :headers => default_headers, :params => {
          :permissions => permissions,
          :group_uuids => %w[1]
        }

        expect(response).to have_http_status(:no_content)
      end
    end
  end
end
