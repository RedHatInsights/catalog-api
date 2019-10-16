describe 'Tagging API' do
  around do |example|
    bypass_rbac do
      example.call
    end
  end

  let!(:portfolio_item) { create(:portfolio_item) }
  let!(:portfolio) { create(:portfolio) }

  before do
    portfolio_item.tag_add("yay")
    portfolio.tag_add("a_tag")
  end

  describe "GET /tags" do
    it "returns a list of tags" do
      get "#{api}/tags", :headers => default_headers

      expect(json["meta"]["count"]).to eq 2
      expect(json["data"].map { |e| e["name"] }).to match_array %w[yay a_tag]
    end
  end

  describe "GET /tags/{id}" do
    it "returns the tag specified" do
      get "#{api}/tags/#{Tag.first.id}", :headers => default_headers

      expect(json["name"]).to eq Tag.first.name
    end
  end

  describe "GET /tags/{id}/portfolio_items" do
    it "returns the tags specified to the portfolio_item" do
      get "#{api}/tags/#{portfolio_item.tags.first.id}/portfolio_items", :headers => default_headers

      expect(json["meta"]["count"]).to eq 1
      expect(json["data"].first["name"]).to eq portfolio_item.name
    end
  end

  describe "GET /tags/{id}/portfolios" do
    it "returns the tags specified to the portfolio_item" do
      get "#{api}/tags/#{portfolio.tags.first.id}/portfolios", :headers => default_headers

      expect(json["meta"]["count"]).to eq 1
      expect(json["data"].first["name"]).to eq portfolio.name
    end
  end
end
