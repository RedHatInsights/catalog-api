describe "v1.0 - Tagging API", :type => [:request, :v1] do
  let(:access_obj) { instance_double(Insights::API::Common::RBAC::Access, :accessible? => true) }
  let(:rbac_aces) { instance_double(Catalog::RBAC::AccessControlEntries) }

  let!(:portfolio_item) { create(:portfolio_item, :portfolio => portfolio) }
  let!(:portfolio) { create(:portfolio) }
  let!(:order_process) { create(:order_process) }
  let(:bad_portfolio_id) { portfolio.id + 1 }
  let(:bad_portfolio_item_id) { portfolio_item.id + 1 }

  let(:catalog_access) { instance_double(Insights::API::Common::RBAC::Access, :scopes => %w[group]) }
  let(:rbac_api) { instance_double(Insights::API::Common::RBAC::Service) }
  let(:group_list) { [RBACApiClient::GroupOut.new(:name => "group", :uuid => "123-456")] }

  before do
    portfolio_item.tag_add("yay")
    portfolio.tag_add("a_tag")
    order_process.tag_add("process_tag")

    allow(Catalog::RBAC::AccessControlEntries).to receive(:new).with(["123-456"]).and_return(rbac_aces)

    allow(Insights::API::Common::RBAC::Access).to receive(:new).and_return(catalog_access)
    allow(catalog_access).to receive(:process).and_return(catalog_access)

    allow(Insights::API::Common::RBAC::Service).to receive(:call).with(RBACApiClient::GroupApi).and_yield(rbac_api)
    allow(Insights::API::Common::RBAC::Service).to receive(:paginate)
      .with(rbac_api, :list_groups, :scope => 'principal')
      .and_return(group_list)
  end

  describe "GET /tags" do
    let(:catalog_access) { instance_double(Insights::API::Common::RBAC::Access, :scopes => %w[admin]) }

    it "returns a list of tags" do
      get "#{api_version}/tags", :headers => default_headers

      expect(json["meta"]["count"]).to eq 3
      expect(json["data"].map { |e| Tag.parse(e["tag"])[:name] }).to match_array %w[yay a_tag process_tag]
    end
  end

  describe "GET /portfolio_items/{id}/tags" do
    context "when requesting all of the tags for a portfolio_item" do
      before do
        allow(rbac_aces).to receive(:ace_ids).with('read', Portfolio).and_return([portfolio.id.to_s])
      end

      it "returns the tags for the portfolio item" do
        get "#{api_version}/portfolio_items/#{portfolio_item.id}/tags", :headers => default_headers

        expect(json["meta"]["count"]).to eq 1
        expect(json["data"].first["tag"]).to eq Tag.new(:name => "yay").to_tag_string
      end

      it "returns not found when portfolio item missing" do
        get "#{api_version}/portfolio_items/#{bad_portfolio_item_id}/tags", :headers => default_headers

        expect(response).to have_http_status(404)
      end
    end

    context "when requesting all tags for a portfolio item you do not have access to" do
      before do
        allow(rbac_aces).to receive(:ace_ids).with('read', Portfolio).and_return([])
      end

      it "returns 404" do
        get "#{api_version}/portfolio_items/#{portfolio_item.id}/tags", :headers => default_headers

        expect(response).to have_http_status(404)
      end
    end
  end

  describe "GET /portfolios/{id}/tags" do
    context "when requesting all of the tags for a portfolio" do
      before do
        allow(rbac_aces).to receive(:ace_ids).with('read', Portfolio).and_return([portfolio.id.to_s])
      end

      it "returns the tags for the portfolio" do
        get "#{api_version}/portfolios/#{portfolio.id}/tags", :headers => default_headers

        expect(json["meta"]["count"]).to eq 1
        expect(json["data"].first["tag"]).to eq Tag.new(:name => "a_tag").to_tag_string
      end

      it "returns not found when portfolio is missing" do
        get "#{api_version}/portfolios/#{bad_portfolio_id}/tags", :headers => default_headers

        expect(response).to have_http_status(404)
      end
    end

    context "when requesting all tags for a portfolio you do not have access to" do
      before do
        allow(rbac_aces).to receive(:ace_ids).with('read', Portfolio).and_return([])
      end

      it "returns a 404" do
        get "#{api_version}/portfolios/#{portfolio.id}/tags", :headers => default_headers

        expect(response).to have_http_status(404)
      end
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
