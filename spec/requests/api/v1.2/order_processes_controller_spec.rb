describe "v1.2 - OrderProcesses", :type => [:request, :controller, :v1x2] do
  let!(:order_process)    { create(:order_process, :name => "OrderProcess_abc") }
  let!(:order_process_id) { order_process.id }
  let(:rbac_access)       { instance_double(Catalog::RBAC::Access) }

  before do
    allow(Catalog::RBAC::Access).to receive(:new).and_return(rbac_access)
    allow(rbac_access).to receive(:read_access_check).and_return(true)
    allow(rbac_access).to receive(:update_access_check).and_return(true)
    allow(rbac_access).to receive(:create_access_check).and_return(true)
    allow(rbac_access).to receive(:destroy_access_check).and_return(true)
    allow(rbac_access).to receive(:link_access_check).and_return(true)
    allow(rbac_access).to receive(:unlink_access_check).and_return(true)
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
          "link"    => true,
          "show"    => true,
          "unlink"  => true,
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

    before do
      allow(Insights::API::Common::RBAC::Access).to receive(:new).and_return(catalog_access)
      allow(catalog_access).to receive(:process).and_return(catalog_access)
    end

    it 'returns 200' do
      get "#{api_version}/order_processes?limit=50&offset=0&filter[name][contains_i]=abc", :headers => default_headers

      expect(response).to have_http_status(200)
      expect(json['data'].size).to eq(1)
      expect(json['data'].first['metadata']).to have_key('user_capabilities')
    end

    it 'returns empty array when filtering out' do
      get "#{api_version}/order_processes?limit=50&offset=0&filter[name][contains_i]=cde", :headers => default_headers

      expect(response).to have_http_status(200)
      expect(json['data'].size).to eq(0)
    end
  end

  describe "POST /order_processes #create" do
    let(:valid_attributes) { {:name => 'itsm_process', :description => "ITSM's OrderProcess"} }

    subject do
      post "#{api_version}/order_processes", :headers => default_headers, :params => valid_attributes
    end

    context "with valid attributes" do
      it "creates an OrderProcess" do
        subject
        expect(response).to have_http_status(200)
      end
    end

    context "with no create permission" do
      it "returns 403" do
        allow(rbac_access).to receive(:create_access_check).and_return(false)

        subject

        expect(response).to have_http_status(403)
      end
    end

    it_behaves_like "action that tests authorization", :create?, OrderProcess
  end

  describe "PATCH /order_processes/:id #update" do
    let(:valid_attributes) { {:name => 'itsm_process', :description => "ITSM's OrderProcess"} }

    subject do
      patch "#{api_version}/order_processes/#{order_process_id}", :headers => default_headers, :params => valid_attributes
    end

    context "with valid attributes" do
      it "updates an OrderProcess" do
        subject
        expect(response).to have_http_status(200)
        updated_order_process = OrderProcess.find(order_process_id)
        expect(updated_order_process).to have_attributes(valid_attributes)
      end
    end

    context "with no update permission" do
      it "returns 403" do
        allow(rbac_access).to receive(:update_access_check).and_return(false)

        subject

        expect(response).to have_http_status(403)
      end
    end

    it_behaves_like "action that tests authorization", :update?, OrderProcess
  end

  describe "PATCH /order_processes/:id/before_portfolio_item #before_portfolio_item" do
    let(:order_process_associator) { instance_double(Api::V1x2::Catalog::OrderProcessAssociator) }
    let!(:before_portfolio_item) { create(:portfolio_item) }
    let(:before_portfolio_item_id) { before_portfolio_item.id.to_s }
    let(:valid_attributes) { {:portfolio_item_id => before_portfolio_item_id} }

    subject do
      patch "#{api_version}/order_processes/#{order_process_id}/before_portfolio_item", :headers => default_headers, :params => valid_attributes
    end

    context "with valid attributes" do
      before do
        allow(Api::V1x2::Catalog::OrderProcessAssociator).to receive(:new)
          .with(order_process, before_portfolio_item_id, :before_portfolio_item)
          .and_return(order_process_associator)
        allow(order_process_associator).to receive(:process).and_return(order_process_associator)
        allow(order_process_associator).to receive(:order_process).and_return(order_process)
      end

      it "delegates to the order process associator" do
        expect(order_process_associator).to receive(:process)
        expect(order_process_associator).to receive(:order_process)
        subject
      end

      it "returns a 200" do
        subject
        expect(response).to have_http_status(200)
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

    context "when the order process does not exist" do
      subject do
        patch "#{api_version}/order_processes/#{order_process_id + 1}/before_portfolio_item", :headers => default_headers
      end

      it "returns a 404" do
        subject
        expect(response).to have_http_status(404)
      end
    end

    it_behaves_like "action that tests authorization", :update?, OrderProcess
  end

  describe "PATCH /order_processes/:id/after_portfolio_item #after_portfolio_item" do
    let(:order_process_associator) { instance_double(Api::V1x2::Catalog::OrderProcessAssociator) }
    let!(:after_portfolio_item) { create(:portfolio_item) }
    let(:after_portfolio_item_id) { after_portfolio_item.id.to_s }
    let(:valid_attributes) { {:portfolio_item_id => after_portfolio_item_id} }

    subject do
      patch "#{api_version}/order_processes/#{order_process_id}/after_portfolio_item", :headers => default_headers, :params => valid_attributes
    end

    context "with valid attributes" do
      before do
        allow(Api::V1x2::Catalog::OrderProcessAssociator).to receive(:new)
          .with(order_process, after_portfolio_item_id, :after_portfolio_item)
          .and_return(order_process_associator)
        allow(order_process_associator).to receive(:process).and_return(order_process_associator)
        allow(order_process_associator).to receive(:order_process).and_return(order_process)
      end

      it "delegates to the order process associator" do
        expect(order_process_associator).to receive(:process)
        expect(order_process_associator).to receive(:order_process)
        subject
      end

      it "returns a 200" do
        subject
        expect(response).to have_http_status(200)
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

    context "when the order process does not exist" do
      subject do
        patch "#{api_version}/order_processes/#{order_process_id + 1}/after_portfolio_item", :headers => default_headers
      end

      it "returns a 404" do
        subject
        expect(response).to have_http_status(404)
      end
    end

    it_behaves_like "action that tests authorization", :update?, OrderProcess
  end

  describe "PATCH /order_processes/:id/return_portfolio_item #return_portfolio_item" do
    let(:order_process_associator) { instance_double(Api::V1x2::Catalog::OrderProcessAssociator) }
    let!(:return_portfolio_item) { create(:portfolio_item) }
    let(:return_portfolio_item_id) { return_portfolio_item.id.to_s }
    let(:valid_attributes) { {:portfolio_item_id => return_portfolio_item_id} }

    subject do
      patch "#{api_version}/order_processes/#{order_process_id}/return_portfolio_item", :headers => default_headers, :params => valid_attributes
    end

    context "with valid attributes" do
      before do
        allow(Api::V1x2::Catalog::OrderProcessAssociator).to receive(:new)
                                                                 .with(order_process, before_portfolio_item_id, :before_portfolio_item)
                                                                 .and_return(order_process_associator)
        allow(order_process_associator).to receive(:process).and_return(order_process_associator)
        allow(order_process_associator).to receive(:order_process).and_return(order_process)
      end

      it "delegates to the order process associator" do
        expect(order_process_associator).to receive(:process)
        expect(order_process_associator).to receive(:order_process)
        subject
      end

      it "returns a 200" do
        subject
        expect(response).to have_http_status(200)
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

    context "when the order process does not exist" do
      subject do
        patch "#{api_version}/order_processes/#{order_process_id + 1}/before_portfolio_item", :headers => default_headers
      end

      it "returns a 404" do
        subject
        expect(response).to have_http_status(404)
      end
    end

    it_behaves_like "action that tests authorization", :update?, OrderProcess
  end

  describe "POST /order_process/:id/remove_association #remove_association" do
    let(:remove_association_params) { {:associations_to_remove => ["before"]} }
    subject do
      post "#{api_version}/order_processes/#{order_process_id}/remove_association",
           :headers => default_headers,
           :params  => remove_association_params
    end

    context "when the order process exists" do
      let(:order_process_dissociator) { instance_double(Api::V1x2::Catalog::OrderProcessDissociator) }

      before do
        allow(Api::V1x2::Catalog::OrderProcessDissociator).to receive(:new)
          .with(order_process, ["before"]).and_return(order_process_dissociator)
        allow(order_process_dissociator).to receive(:process).and_return(order_process_dissociator)
        allow(order_process_dissociator).to receive(:order_process).and_return(order_process)
      end

      it "delegates to the order process dissociator service" do
        expect(order_process_dissociator).to receive(:process)
        expect(order_process_dissociator).to receive(:order_process)
        subject
      end

      it "returns a 200" do
        subject
        expect(response).to have_http_status(200)
      end
    end

    context "when the order process does not exist" do
      let(:order_process_id) { order_process.id + 1 }

      it "returns a 404" do
        subject
        expect(response).to have_http_status(404)
      end
    end

    it_behaves_like "action that tests authorization", :update?, OrderProcess
  end

  describe "DELETE /order_processes #destroy" do
    subject { delete "#{api_version}/order_processes/#{order_process_id}", :headers => default_headers }

    it "allows to delete order process" do
      subject
      expect(response).to have_http_status(204)
    end

    it_behaves_like "action that tests authorization", :destroy?, OrderProcess
  end

  describe "POST /order_processes/:id/link #link" do
    context "when object type is PortfolioItem" do
      let(:portfolio_item) { create(:portfolio_item) }
      let(:tag_attrs) { {:object_type => 'PortfolioItem', :app_name => 'catalog', :object_id => portfolio_item.id.to_s} }

      it "returns 204" do
        post "#{api_version}/order_processes/#{order_process_id}/link", :headers => default_headers, :params => tag_attrs
        expect(response).to have_http_status(204)

        expect(TagLink.count).to eq(1)
        expect(TagLink.first).to have_attributes(:order_process_id => order_process.id,
                                                 :app_name         => "catalog",
                                                 :object_type      => "PortfolioItem",
                                                 :tag_name         => "/catalog/order_processes=#{order_process_id}")

        expect(portfolio_item.tags.count).to eq(1)
        expect(portfolio_item.tags.first).to have_attributes(:name      => "order_processes",
                                                             :value     => order_process.id.to_s,
                                                             :namespace => "catalog")
      end
    end

    context "when object type is ServiceInventory" do
      let(:tag_attrs) { {:object_type => 'ServiceInventory', :app_name => 'catalog-inventory', :object_id => "123"} }
      let(:link_tag_svc) { instance_double("Api::V1x2::Catalog::LinkToOrderProcess") }

      it "returns 204" do
        allow(Api::V1x2::Catalog::LinkToOrderProcess).to receive(:new).and_return(link_tag_svc)
        allow(link_tag_svc).to receive(:process).and_return(link_tag_svc)

        post "#{api_version}/order_processes/#{order_process_id}/link", :headers => default_headers, :params => tag_attrs

        expect(response).to have_http_status(204)
      end
    end

    context "when object type is Source" do
      let(:tag_attrs) { {:object_type => 'Source', :app_name => 'sources', :object_id => "123"} }
      let(:link_tag_svc) { instance_double("Api::V1x2::Catalog::LinkToOrderProcess") }

      it "returns 204" do
        allow(Api::V1x2::Catalog::LinkToOrderProcess).to receive(:new).and_return(link_tag_svc)
        allow(link_tag_svc).to receive(:process).and_return(link_tag_svc)

        post "#{api_version}/order_processes/#{order_process_id}/link", :headers => default_headers, :params => tag_attrs

        expect(response).to have_http_status(204)
      end
    end
  end

  describe "POST /order_processes/:id/unlink #unlink" do
    context "when object type is Portfolio" do
      let(:portfolio) { create(:portfolio) }
      let(:tag_attrs) { {:object_type => 'Portfolio', :app_name => 'catalog', :object_id => portfolio.id.to_s} }

      it "returns 204" do
        post "#{api_version}/order_processes/#{order_process_id}/link", :headers => default_headers, :params => tag_attrs

        expect(TagLink.count).to eq(1)
        expect(TagLink.first).to have_attributes(:order_process_id => order_process.id,
                                                 :app_name         => "catalog",
                                                 :object_type      => "Portfolio",
                                                 :tag_name         => "/catalog/order_processes=#{order_process_id}")

        expect(portfolio.tags.count).to eq(1)
        expect(portfolio.tags.first).to have_attributes(:name      => "order_processes",
                                                        :value     => order_process.id.to_s,
                                                        :namespace => "catalog")

        post "#{api_version}/order_processes/#{order_process_id}/unlink", :headers => default_headers, :params => tag_attrs
        portfolio.reload

        expect(response).to have_http_status(204)

        expect(TagLink.count).to eq(0)
        expect(portfolio.tags.count).to eq(0)
      end
    end

    context "when object type is ServiceInventory" do
      let(:tag_attrs) { {:object_type => 'ServiceInventory', :app_name => 'catalog-inventory', :object_id => "123"} }
      let(:unlink_tag_svc) { instance_double("Api::V1x2::Catalog::UnlinkFromOrderProcess") }

      it "returns 204" do
        allow(Api::V1x2::Catalog::UnlinkFromOrderProcess).to receive(:new).and_return(unlink_tag_svc)
        allow(unlink_tag_svc).to receive(:process).and_return(unlink_tag_svc)

        post "#{api_version}/order_processes/#{order_process_id}/unlink", :headers => default_headers, :params => tag_attrs
        expect(response).to have_http_status(204)
      end
    end
  end

  describe "GET /order_processes #link_tags" do
    let(:catalog_access) { instance_double(Insights::API::Common::RBAC::Access, :scopes => %w[admin]) }

    before do
      allow(Insights::API::Common::RBAC::Access).to receive(:new).and_return(catalog_access)
      allow(catalog_access).to receive(:process).and_return(catalog_access)
    end

    context "when app is catalog" do
      let(:portfolio) { create(:portfolio) }
      let(:tag_attrs) { {:object_type => 'Portfolio', :app_name => 'catalog', :object_id => portfolio.id.to_s} }

      it 'returns 200' do
        post "#{api_version}/order_processes/#{order_process_id}/link", :headers => default_headers, :params => tag_attrs

        get "#{api_version}/order_processes", :headers => default_headers, :params => tag_attrs

        expect(response).to have_http_status(200)
      end
    end

    context "when app is catalog-inventory" do
      let(:tag_attrs) { {:object_type => 'ServiceInventory', :app_name => 'catalog-inventory', :object_id => "123"} }
      let(:get_tag_svc) { instance_double("Api::V1x2::Catalog::GetLinkedOrderProcess") }

      it "returns 200" do
        allow(Api::V1x2::Catalog::GetLinkedOrderProcess).to receive(:new).and_return(get_tag_svc)
        allow(get_tag_svc).to receive(:process).and_return(get_tag_svc)
        allow(get_tag_svc).to receive(:order_processes).and_return(OrderProcess.all)

        get "#{api_version}/order_processes", :headers => default_headers, :params => tag_attrs

        expect(response).to have_http_status(200)
      end
    end

    context "when resource params is invalid" do
      let(:bad_attrs) { {:object_type => 'ServiceInventory', :app_name => 'catalog-inventory'} }
      let(:get_tag_svc) { instance_double("Api::V1x2::Catalog::GetLinkedOrderProcess") }

      it "raises an error" do
        allow(Api::V1x2::Catalog::GetLinkedOrderProcess).to receive(:new).and_return(get_tag_svc)
        allow(get_tag_svc).to receive(:process).and_return(get_tag_svc)
        allow(get_tag_svc).to receive(:order_processes).and_return(OrderProcess.all)

        get "#{api_version}/order_processes", :headers => default_headers, :params => bad_attrs

        expect(response).to have_http_status(400)
        expect(response.body).to match(/Catalog::InvalidParameter: Invalid resource object params/)
      end
    end
  end
end
