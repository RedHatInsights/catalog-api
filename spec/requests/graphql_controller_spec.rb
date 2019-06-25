RSpec.describe("v1.0 - GraphQL") do
  around do |example|
    bypass_rbac do
      example.call
    end
  end

  let(:tenant) { create(:tenant) }
  let!(:portfolio_a) { create(:portfolio, :tenant_id => tenant.id, :description => 'test a desc', :name => "test_a", :owner => "234") }
  let!(:portfolio_b) { create(:portfolio, :tenant_id => tenant.id, :description => 'test b desc', :name => "test_b", :owner => "123") }
  let!(:portfolio_c) { create(:portfolio, :tenant_id => tenant.id, :description => 'test c desc', :name => "test_c", :owner => "321") }

  let!(:portfolio_item_a) { create(:portfolio_item, :portfolio => portfolio_a, :name => 'portfolio item a') }
  let!(:order_a) { create(:order, :tenant_id => tenant.id) }
  let!(:order_item) { create(:order_item, :order_id => order_a.id, :portfolio_item_id => portfolio_item_a.id, :tenant_id => tenant.id) }

  let(:graphql_portfolio_query) { { "query" => "{ portfolios {  name id } }" } }

  def result_portfolios(response_body)
    JSON.parse(response_body).fetch_path("data", "portfolios")
  end

  # if graphql query fails it does not return 5xx or 4xx it adds "errors key" to the response object response.status it not enough to check sucessfull response
  def positive_graphql_response(response)
    response.parsed_body["data"]
  end

  context "different graphql queries" do
    before do
      post("/api/v1.0/graphql", :headers => default_headers, :params => graphql_portfolio_query)
    end

    it "querying portfolios return portfolio ids" do
      expect(response.status).to eq(200)
      expect(positive_graphql_response(response)).to be_truthy
      result_portfolio_ids = result_portfolios(response.body).collect { |portfolio| portfolio.fetch_path("id").to_i }
      expect(result_portfolio_ids).to match_array([portfolio_a.id, portfolio_b.id, portfolio_c.id])
    end
    
    it "querying portfolios return portfolio names" do
      expect(response.status).to eq(200)
      expect(positive_graphql_response(response)).to be_truthy
      result_portfolio_names = result_portfolios(response.body).collect { |portfolio| portfolio.fetch_path("name") }
      expect(result_portfolio_names).to match_array([portfolio_a.name, portfolio_b.name, portfolio_c.name])
    end
  end
  
  context "filtering queries" do
    it "portfolios using attribute should return porfolio names and ids" do
      # direct attributes filtering does not work
      post(
        "/api/v1.0/graphql",
        :headers => default_headers,
        :params  => { "query" => "{ portfolios(name: \"#{portfolio_a.name}\") { id name } }" }
      )
      result = result_portfolios(response.body)
      expect(response.status).to eq(200)
      expect(positive_graphql_response(response)).to be_truthy
      expect(result.length).to be(1)
      expect(result[0]).to include("node" => { "id" => portfolio_a.id.to_s, "name" => portfolio_a.name })
    end

    it "portfolios using filter parameters should return porfolio names and ids" do
      # direct attributes filtering does not work
      post(
        "/api/v1.0/graphql",
        :headers => default_headers,
        :params  => { "query" => "{ portfolios(filter: {name: \"#{portfolio_a.name}\"}) { id name } }" }
      )
      result = result_portfolios(response.body)
      expect(response.status).to eq(200)
      expect(positive_graphql_response(response)).to be_truthy
      expect(result.length).to be(1)
      expect(result[0]).to include("id" => portfolio_a.id.to_s, "name" => portfolio_a.name)
    end

    it "by multiple ids in via direct attributes and return list of portfolios" do
      # direct attributes filtering does not work
      # using ID should work but returns an error with invalid ID type: Argument 'id' on Field 'portfolios' has an invalid value. Expected type 'ID'.
      post(
        "/api/v1.0/graphql",
        :headers => default_headers,
        :params  => { "query" => "{ portfolios(id: [\"#{portfolio_a.id.to_s}\", \"#{portfolio_b.id.to_s}\"]) { id name } }" }
      )
      result = result_portfolios(response.body)
      expect(response.status).to eq(200)
      expect(positive_graphql_response(response)).to be_truthy
      expect(result.length).to be(2)
      expect(result).to include({"node" => { "id" => portfolio_a.id.to_s, "name" => portfolio_a.name }}, {"node" => { "id" => portfolio_b.id.to_s, "name" => portfolio_b.name }})
    end

    it "by multiple ids in via filter parameters attributes and return list of portfolios" do
      post(
        "/api/v1.0/graphql",
        :headers => default_headers,
        :params  => { "query" => "{ portfolios(filter: {id: [\"#{portfolio_a.id}\", \"#{portfolio_b.id}\"]}) { id name } }" }
      )
      result = result_portfolios(response.body)
      expect(response.status).to eq(200)
      expect(positive_graphql_response(response)).to be_truthy
      expect(result.length).to be(2)
      expect(result).to include(
        {"id" => portfolio_a.id.to_s, "name" => portfolio_a.name },
        { "id" => portfolio_b.id.to_s, "name" => portfolio_b.name }
      )
    end
  end

  context "pagination queries" do
    # limit offset pagination should work after relay based spec will be removed
    let(:graphql_portfolio_paginated_query) { { "query" => "{ portfolios(limit: 1 offset: 1) { id name } }" } }

    it "paginate portfolios" do
      post("/api/v1.0/graphql", :headers => default_headers, :params => graphql_portfolio_paginated_query)
      result = result_portfolios(response.body)
      expect(response.status).to eq(200)
      expect(positive_graphql_response(response)).to be_truthy
      expect(result.length).to eq(1)
      expect(result).to include({ "id" => portfolio_b.id.to_s, "name" => portfolio_b.name })
    end
  end

  context "association queries" do
    let(:graphql_portfolio_association_query) { { "query" => "{ portfolios { id, portfolioItems { id } } }" } }

    it "should add order items to portfolios" do
      post("/api/v1.0/graphql", :headers => default_headers, :params => graphql_portfolio_association_query)
      expect(response.status).to eq(200)
      expect(positive_graphql_response(response)).to be_truthy
    end
  end
end
