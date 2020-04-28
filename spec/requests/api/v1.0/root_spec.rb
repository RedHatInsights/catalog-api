describe "v1.0 - root", :type => [:request, :v1] do
  it "#openapi.json" do
    get("#{api_version}/openapi.json")

    expect(response.content_type).to eq("application/json")
    expect(response).to have_http_status(:ok)
  end
end
