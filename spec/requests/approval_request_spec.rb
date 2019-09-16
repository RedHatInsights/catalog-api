describe "ApprovalRequestRequests", :type => :request do
  around do |example|
    bypass_rbac do
      example.call
    end
  end

  let!(:approval_request) { create(:approval_request) }

  context "v1.0" do
    it "lists progress messages" do
      get "/#{api}/order_items/#{approval_request.order_item.id}/approval_requests", :headers => default_headers

      expect(response.content_type).to eq("application/json")
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['data'].first['id']).to eq(approval_request.id.to_s)
    end

    context "when the order item does not exist" do
      it "returns a 404" do
        get "/#{api}/order_items/0/approval_requests", :headers => default_headers

        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)['message']).to eq("Not Found")
      end
    end
  end
end
