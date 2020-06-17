describe "v1 - root", :type => [:request, :v1x2] do
  it "#openapi.json" do
    get("#{api_version}/openapi.json")

    expect(response.content_type).to eq("application/json")
    expect(response).to have_http_status(:ok)
  end

  it "handles redirects correctly" do
    get("/api/catalog/v1/openapi.json")

    expect(response.status).to eq(302)
    expect(response.headers["Location"]).to eq("#{api_version}/openapi.json")
  end
end
