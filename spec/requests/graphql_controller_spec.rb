RSpec.describe("v1.0 - GraphQL") do

  around do |example|
    bypass_rbac do
      example.call
    end
  end

  let(:tenant)      { create(:tenant) }
  let!(:portfolio_a) { create(:portfolio, :tenant_id => tenant.id, :description => 'test a desc', :name => "test_a", :owner => "234") }
  let!(:portfolio_b) { create(:portfolio, :tenant_id => tenant.id, :description => 'test b desc', :name => "test_b", :owner => "123") }

  let(:graphql_portfolio_query) { { "query" => "{ portfolios { edges { node { id name } } } }" } }

  def result_portfolio_ids(response_body)
    JSON.parse(response_body).fetch_path("data", "portfolios", "edges").collect { |edge| edge.fetch_path("node", "id").to_i }
  end

  def result_portfolio_names(response_body)
    JSON.parse(response_body).fetch_path("data", "portfolios", "edges").collect { |edge| edge.fetch_path("node", "name") }
  end

  context "different graphql queries" do
    before do
      post("/api/v1.0/graphql", :headers => default_headers, :params => graphql_portfolio_query)
    end

    it "querying portfolios return portfolio ids" do
      expect(response.status).to eq(200)
      expect(result_portfolio_ids(response.body)).to match_array([portfolio_a.id, portfolio_b.id])
    end

    it "querying portfolios return portfolio names" do
      expect(response.status).to eq(200)
      expect(result_portfolio_names(response.body)).to match_array([portfolio_a.name, portfolio_b.name])
    end
  end
end
