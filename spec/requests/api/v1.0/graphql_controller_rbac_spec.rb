describe "v1.0 - Portfolios Read Access RBAC API", :type => [:request, :v1] do
  let!(:portfolio1) { create(:portfolio) }
  let(:graphql_query) { '{ portfolios { id name } }' }
  let(:graphql_body) { { 'query' => graphql_query } }

  let(:catalog_access) { instance_double(Insights::API::Common::RBAC::Access, :scopes => %w[admin]) }

  before do
    allow(Insights::API::Common::RBAC::Access).to receive(:new).and_return(catalog_access)
    allow(catalog_access).to receive(:process).and_return(catalog_access)
  end

  describe "GET /portfolios" do
    context "via graphql" do
      let(:graphql_query) { "{ portfolios(id: #{portfolio1.id}) { id name } }" }

      it 'ok' do
        post "#{api_version}/graphql", :headers => default_headers, :params => graphql_body
        expect(response).to have_http_status(:ok)
        expect(json['data']['portfolios'][0]['name']).to eq(portfolio1.name)
      end
    end
  end
end
