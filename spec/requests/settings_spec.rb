describe 'Settings API' do
  let!(:tenant) do
    create(:tenant,
           :settings => {
             :icon             => "<svg rel='stylesheet'>image</svg>",
             :default_workflow => "1"
           })
  end
  let(:retreived_tenant) { Tenant.find(tenant.id) }

  let(:org_admin_hash) do
    user = default_user_hash
    user["identity"]["user"]["is_org_admin"] = true
    encoded_user_hash(user)
  end

  let(:manipulated_headers) do
    { 'x-rh-identity'            => org_admin_hash,
      'x-rh-insights-request-id' => 'gobbledygook' }
  end

  context "when the user is an org admin" do
    describe "#index" do
      before { get "#{api}/settings", :headers => manipulated_headers }

      it "returns the index of settings per tenant" do
        expect(response).to have_http_status(:ok)
        expect(json["icon"]).to eq retreived_tenant.icon
        expect(json["default_workflow"]).to eq retreived_tenant.default_workflow
      end
    end

    describe "#show" do
      before { get "#{api}/settings/icon", :headers => manipulated_headers }

      it "returns the specified setting" do
        expect(response).to have_http_status(:ok)
        expect(json["icon"]).to eq retreived_tenant.icon
      end
    end

    describe "#create" do
      let(:params) { { :name => "new_setting", :value => "17" } }
      before { post "#{api}/settings", :headers => manipulated_headers, :params => params }

      it "creates a new setting" do
        expect(response).to have_http_status(:ok)
        expect(json["new_setting"]).to eq params[:value]
      end
    end

    describe "#update" do
      let(:params) { { :value => "<svg rel='stylesheet'>new image!</svg>" } }

      before { patch "#{api}/settings/icon", :headers => manipulated_headers, :params => params }

      it "patches the settings" do
        expect(response).to have_http_status(:ok)
        expect(json["icon"]).to eq params[:value]
      end
    end

    describe "#delete" do
      before { delete "#{api}/settings/default_workflow", :headers => manipulated_headers }

      it "deletes the specified setting" do
        expect(response).to have_http_status(:no_content)
        expect(retreived_tenant.settings.key?("default_workflow")).to be_falsey
      end
    end
  end

  context "when the user is not an org admin" do
    it "does not allow any operations" do
      get "#{api}/settings", :headers => default_headers

      expect(response).to have_http_status(:forbidden)
    end
  end
end
