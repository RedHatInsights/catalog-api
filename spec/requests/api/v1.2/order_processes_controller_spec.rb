describe "v1.2 - OrderProcesses", :type => [:request, :controller, :v1x2] do
  let!(:order_process)    { create(:order_process) }
  let!(:order_process_id) { order_process.id }
  let(:rbac_access)       { instance_double(Catalog::RBAC::Access) }

  before do
    allow(Catalog::RBAC::Access).to receive(:new).and_return(rbac_access)
    allow(rbac_access).to receive(:read_access_check).and_return(true)
    allow(rbac_access).to receive(:update_access_check).and_return(true)
    allow(rbac_access).to receive(:create_access_check).and_return(true)
    allow(rbac_access).to receive(:destroy_access_check).and_return(true)
  end

  describe "GET /order_processes/:id #show" do
    context "when the order process exists" do
      it "returns 200" do
        get "#{api_version}/order_processes/#{order_process_id}", :headers => default_headers

        expect(response).to have_http_status(200)
      end

      it "returns with metadata" do
        get "#{api_version}/order_processes/#{order_process_id}", :headers => default_headers

        expect(json).not_to be_empty
        expect(json['id']).to eq(order_process_id.to_s)
        expect(json['created_at']).to eq(order_process.created_at.iso8601)
        expect(json['metadata']).to have_key('user_capabilities')
        expect(json['metadata']['user_capabilities']).to eq(
          "create"  => true,
          "show"    => true,
          "update"  => true,
          "destroy" => true
        )
      end
    end

    context 'when the order process does not exist' do
      let(:order_process_id) { 0 }

      it "cannot be requested" do
        get "#{api_version}/order_processes/#{order_process_id}", :headers => default_headers

        expect(response).to have_http_status(404)
      end
    end
  end

  describe "GET /order_processes #index" do
    let(:catalog_access) { instance_double(Insights::API::Common::RBAC::Access, :scopes => %w[admin]) }

    it 'returns 200' do
      allow(Insights::API::Common::RBAC::Access).to receive(:new).and_return(catalog_access)
      allow(catalog_access).to receive(:process).and_return(catalog_access)

      get "#{api_version}/order_processes", :headers => default_headers

      expect(response).to have_http_status(200)
      expect(json['data'].size).to eq(1)
      expect(json['data'].first['metadata']).to have_key('user_capabilities')
    end
  end

  describe "POST /order_processes #create" do
    let(:valid_attributes) { {:name => 'itsm_process', :description => "ITSM's OrderProcess"} }

    context "with valid attributes" do
      it "creates an OrderProcess" do
        post "#{api_version}/order_processes", :headers => default_headers, :params => valid_attributes

        expect(response).to have_http_status(200)
      end
    end

    context "with no create permission" do
      it "returns 403" do
        allow(rbac_access).to receive(:create_access_check).and_return(false)

        post "#{api_version}/order_processes", :headers => default_headers, :params => valid_attributes

        expect(response).to have_http_status(403)
      end
    end
  end

  describe "PATCH /order_processes/:id #update" do
    let(:valid_attributes) { {:name => 'itsm_process', :description => "ITSM's OrderProcess"} }

    context "with valid attributes" do
      it "updates an OrderProcess" do
        patch "#{api_version}/order_processes/#{order_process_id}", :headers => default_headers, :params => valid_attributes

        expect(response).to have_http_status(200)
        updated_order_process = OrderProcess.find(order_process_id)
        expect(updated_order_process).to have_attributes(valid_attributes)
      end
    end

    context "with no update permission" do
      it "returns 403" do
        allow(rbac_access).to receive(:update_access_check).and_return(false)

        patch "#{api_version}/order_processes/#{order_process_id}", :headers => default_headers, :params => valid_attributes

        expect(response).to have_http_status(403)
      end
    end
  end

  describe "PATCH /order_processes/:id/pre #pre" do
    let(:valid_attributes) { {:portfolio_item_id => pre_portfolio_item_id} }

    subject do
      patch "#{api_version}/order_processes/#{order_process_id}/pre", :headers => default_headers, :params => valid_attributes
    end

    context "with valid attributes" do
      let!(:pre_portfolio_item) { create(:portfolio_item) }
      let(:pre_portfolio_item_id) { pre_portfolio_item.id.to_s }

      it "updates an OrderProcess" do
        subject
        expect(response).to have_http_status(200)
        expect(json["pre_id"]).to eq(pre_portfolio_item.id.to_s)
        updated_order_process = OrderProcess.find(order_process_id)
        expect(updated_order_process.pre).to eq(pre_portfolio_item)
      end

      context "with no update permission" do
        before do
          allow(rbac_access).to receive(:update_access_check).and_return(false)
        end

        it "returns 403" do
          subject
          expect(response).to have_http_status(403)
        end
      end
    end

    context "when no portfolio item exists with the given id" do
      let(:pre_portfolio_item_id) { "1234" }

      it "returns a 404" do
        subject
        expect(response).to have_http_status(404)
      end
    end
  end

  describe "DELETE /order_processes #destroy" do
    it "allows to delete order process" do
      delete "#{api_version}/order_processes/#{order_process_id}", :headers => default_headers
      expect(response).to have_http_status(204)
    end
  end

  it_behaves_like "controller that supports tagging endpoints" do
    let(:object_instance) { order_process }
  end
end
