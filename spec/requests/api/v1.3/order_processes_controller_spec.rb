describe "v1.3 - OrderProcesses", :type => [:request, :controller, :v1x3] do
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
          .with(order_process, return_portfolio_item_id, :return_portfolio_item)
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
        patch "#{api_version}/order_processes/#{order_process_id + 1}/return_portfolio_item", :headers => default_headers
      end

      it "returns a 404" do
        subject
        expect(response).to have_http_status(404)
      end
    end

    it_behaves_like "action that tests authorization", :update?, OrderProcess
  end

  describe "POST /order_process/:id/remove_association #remove_association" do
    let(:remove_association_params) { {:associations_to_remove => ["return"]} }
    subject do
      post "#{api_version}/order_processes/#{order_process_id}/remove_association",
           :headers => default_headers,
           :params  => remove_association_params
    end

    context "when the order process exists" do
      let(:order_process_dissociator) { instance_double(Api::V1x2::Catalog::OrderProcessDissociator) }

      before do
        allow(Api::V1x2::Catalog::OrderProcessDissociator).to receive(:new)
          .with(order_process, ["return"]).and_return(order_process_dissociator)
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

  describe 'POST /order_processes/:id/reposition' do
    it 'returns status code 204 for positive numeric increment' do
      post "#{api_version}/order_processes/#{order_process_id}/reposition", :params => {:increment => 1}, :headers => default_headers

      expect(response).to have_http_status(204)
    end

    it 'returns status code 204 for negative numeric increment' do
      post "#{api_version}/order_processes/#{order_process_id}/reposition", :params => {:increment => -1}, :headers => default_headers

      expect(response).to have_http_status(204)
    end

    it 'returns status code 204 for bottom increment' do
      post "#{api_version}/order_processes/#{order_process_id}/reposition", :params => {:placement => 'bottom'}, :headers => default_headers

      expect(response).to have_http_status(204)
    end

    it 'returns status code 400 for non-recognized increment' do
      post "#{api_version}/order_processes/#{order_process_id}/reposition", :params => {:placement => 'bad'}, :headers => default_headers

      expect(response).to have_http_status(400)
    end

    it 'returns status code 204 for nullable value' do
      post "#{api_version}/order_processes/#{order_process_id}/reposition", :params => {:placement => nil, :increment => 1}, :headers => default_headers

      expect(response).to have_http_status(204)
    end

    it 'returns status code 400 when both placement and increment are set' do
      post "#{api_version}/order_processes/#{order_process_id}/reposition", :params => {:placement => 'top', :increment => 1}, :headers => default_headers

      expect(response).to have_http_status(400)
    end
  end
end
