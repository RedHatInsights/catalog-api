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

  describe "Multiple Tags" do
    context "when only populating the name" do
      it "re-uses the same tag in the database" do
        portfolio.tag_add("Fred")
        portfolio_item.tag_add("Fred")

        portfolio_tag = portfolio.tags.where(:name => "Fred").first
        portfolio_item_tag = portfolio_item.tags.where(:name => "Fred").first

        expect(portfolio_tag.id).to eq portfolio_item_tag.id
      end
    end

    context "when matching name, namespace, and value" do
      it "re-uses the same tag in the database" do
        portfolio.tag_add("Barney", :namespace => "catalog", :value => "yes")
        portfolio_item.tag_add("Barney", :namespace => "catalog", :value => "yes")

        portfolio_tag = portfolio.tags.where(:name => "Barney").first
        portfolio_item_tag = portfolio_item.tags.where(:name => "Barney").first

        expect(portfolio_tag.id).to eq portfolio_item_tag.id
      end
    end

    context "when only matching name" do
      it "does not re-use the tag in the database" do
        portfolio.tag_add("Wilma", :namespace => "catalog", :value => "yes")
        portfolio_item.tag_add("Wilma", :namespace => "catalog", :value => "no")

        portfolio_tag = portfolio.tags.where(:name => "Wilma").first
        portfolio_item_tag = portfolio_item.tags.where(:name => "Wilma").first

        expect(portfolio_tag.id).not_to eq portfolio_item_tag.id
      end
    end
  end
end
