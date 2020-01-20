describe "v1.0 - ApprovalRequestRequests", :type => [:request, :v1] do
  around do |example|
    bypass_rbac do
      example.call
    end
  end

  let!(:approval_request) { create(:approval_request) }

  it "lists progress messages" do
    get "#{api_version}/order_items/#{approval_request.order_item.id}/approval_requests", :headers => default_headers

    expect(response.content_type).to eq("application/json")
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)['data'].first['id']).to eq(approval_request.id.to_s)
  end

  context "when the order item does not exist" do
    it "returns a 404" do
      get "#{api_version}/order_items/0/approval_requests", :headers => default_headers

      expect(response.content_type).to eq("application/json")
      expect(response).to have_http_status(:not_found)
      expect(first_error_detail).to match(/Couldn't find OrderItem/)
    end
  end
end
