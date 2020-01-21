describe "v1.0 - GraphQL", :type => [:request, :v1] do
  around do |example|
    bypass_rbac do
      example.call
    end
  end

  let!(:portfolio_a) { create(:portfolio, :description => 'test a desc', :name => "test_a", :owner => "234") }
  let!(:portfolio_b) { create(:portfolio, :description => 'test b desc', :name => "test_b", :owner => "123") }

  let(:graphql_portfolio_query) { { "query" => "{ portfolios { id name } }" } }

  def result_portfolios(response_body)
    JSON.parse(response_body).fetch_path("data", "portfolios")
  end

  context "different graphql queries" do
    before do
      post("#{api_version}/graphql", :headers => default_headers, :params => graphql_portfolio_query)
    end

    it "querying portfolios return portfolio ids" do
      expect(response.status).to eq(200)
      result_portfolio_ids = result_portfolios(response.body).collect { |pf| pf["id"].to_i }
      expect(result_portfolio_ids).to match_array([portfolio_a.id, portfolio_b.id])
    end

    it "querying portfolios return portfolio names" do
      expect(response.status).to eq(200)
      result_portfolio_names = result_portfolios(response.body).collect { |pf| pf["name"] }
      expect(result_portfolio_names).to match_array([portfolio_a.name, portfolio_b.name])
    end
  end
end
