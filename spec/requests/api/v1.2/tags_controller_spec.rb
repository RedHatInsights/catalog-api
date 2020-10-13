describe "v1.2 - Tags", :type => [:request, :controller, :v1x2] do
  let!(:order_process)    { create(:order_process, :name => "OrderProcess_abc") }
  let!(:order_process_id) { order_process.id }
  let!(:portfolio_item) { create(:portfolio_item, :portfolio => portfolio) }
  let!(:portfolio) { create(:portfolio) }
  let(:bad_portfolio_id) { portfolio.id + 1 }
  let(:bad_portfolio_item_id) { portfolio_item.id + 1 }

  let(:access_obj) { instance_double(Insights::API::Common::RBAC::Access, :accessible? => true) }
  let(:rbac_aces) { instance_double(Catalog::RBAC::AccessControlEntries) }
  let(:catalog_access) { instance_double(Insights::API::Common::RBAC::Access, :scopes => %w[group]) }
  let(:rbac_api) { instance_double(Insights::API::Common::RBAC::Service) }
  let(:group_list) { [RBACApiClient::GroupOut.new(:name => "group", :uuid => "123-456")] }

  before do
    portfolio_item.tag_add("yay")
    portfolio.tag_add("a_tag")

    allow(Insights::API::Common::RBAC::Access).to receive(:new).and_return(catalog_access)
    allow(catalog_access).to receive(:process).and_return(catalog_access)
    allow(Catalog::RBAC::AccessControlEntries).to receive(:new).with(["123-456"]).and_return(rbac_aces)
    allow(Insights::API::Common::RBAC::Service).to receive(:call).with(RBACApiClient::GroupApi).and_yield(rbac_api)
    allow(Insights::API::Common::RBAC::Service).to receive(:paginate)
      .with(rbac_api, :list_groups, :scope => 'principal')
      .and_return(group_list)
  end

  describe "GET /tags" do
    let(:catalog_access) { instance_double(Insights::API::Common::RBAC::Access, :scopes => %w[admin]) }

    it "returns a list of tags" do
      get "#{api_version}/tags", :headers => default_headers

      expect(json["meta"]["count"]).to eq 2
      expect(json["data"].map { |e| Tag.parse(e["tag"])[:name] }).to match_array %w[yay a_tag]
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
end
