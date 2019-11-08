describe 'Settings API', :type => :request do
  let!(:tenant) { create(:tenant) }
  let(:retreived_tenant) { Tenant.find(tenant.id) }

  context "when the user is a catalog admin" do
    before { allow(ManageIQ::API::Common::RBAC::Roles).to receive(:assigned_role?).with(catalog_admin_role).and_return(true) }

    describe "#index" do
      before { get "#{api}/settings", :headers => default_headers }

      it "returns the current settings of the tenant" do
        expect(response).to have_http_status(:ok)
        expect(json["current"]["icon"]).to eq retreived_tenant.icon
        expect(json["current"]["default_workflow"]).to eq retreived_tenant.default_workflow
      end

      it 'returns the json schema as well' do
        expect(json["schema"]).to eq JSON.parse(Catalog::TenantSettings.new(tenant).send(:schema))
      end
    end

    describe "#show" do
      before { get "#{api}/settings/icon", :headers => default_headers }

      it "returns the specified setting" do
        expect(response).to have_http_status(:ok)
        expect(json["icon"]).to eq retreived_tenant.icon
      end
    end

    describe "#create" do
      let(:params) { { :name => "new_setting", :value => "17" } }
      before { post "#{api}/settings", :headers => default_headers, :params => params }

      it "creates a new setting" do
        expect(response).to have_http_status(:ok)
        expect(json["new_setting"]).to eq params[:value]
      end
    end

    describe "#update" do
      let(:params) { { :value => "<svg rel='stylesheet'>new image!</svg>" } }
      before { patch "#{api}/settings/icon", :headers => default_headers, :params => params }

      it "patches the settings" do
        expect(response).to have_http_status(:ok)
        expect(json["icon"]).to eq params[:value]
      end
    end

    describe "#delete" do
      before { delete "#{api}/settings/default_workflow", :headers => default_headers }

      it "deletes the specified setting" do
        expect(response).to have_http_status(:no_content)
        expect(retreived_tenant.settings.key?("default_workflow")).to be_falsey
      end
    end

    context "when the key already exists" do
      describe "#create" do
        let(:params) { { :name => "icon", :value => "17" } }
        before { post "#{api}/settings", :headers => default_headers, :params => params }

        it "returns a 400" do
          expect(response).to have_http_status(:bad_request)
        end
      end
    end

    context "when the key does not exist" do
      describe "#update" do
        let(:params) { { :value => "<svg rel='stylesheet'>new image!</svg>" } }
        before { patch "#{api}/settings/a_fake_setting", :headers => default_headers, :params => params }

        it "returns a 404" do
          expect(response).to have_http_status(:not_found)
        end
      end

      describe "#delete" do
        before { delete "#{api}/settings/not_real", :headers => default_headers }

        it "returns a 404" do
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  context "when the user is not a catalog admin" do
    before { allow(ManageIQ::API::Common::RBAC::Roles).to receive(:assigned_role?).with(catalog_admin_role).and_return(false) }

    it "does not allow any operations" do
      get "#{api}/settings", :headers => default_headers

      expect(response).to have_http_status(:forbidden)
    end
  end
end
