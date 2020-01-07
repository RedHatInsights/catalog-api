describe "v1.0 - root", :type => [:request, :v1] do
  it "#openapi.json" do
    get("/#{api_version}/openapi.json", :headers => default_headers)

    expect(response.content_type).to eq("application/json")
    expect(response).to have_http_status(:ok)
  end

  it "handles redirects correctly" do
    get("/api/v1/openapi.json", :headers => default_headers)

    expect(response.status).to eq(302)
    expect(response.headers["Location"]).to eq("#{api_version}/openapi.json")
  end
end
