describe 'Portfolios Read Access RBAC API' do
  let!(:portfolio1) { create(:portfolio) }
  let!(:portfolio2) { create(:portfolio) }
  let(:access_obj) { instance_double(ManageIQ::API::Common::RBAC::Access, :owner_scoped? => false, :accessible? => true, :id_list => id_list) }
  let(:valid_attributes) { {:name => 'Fred', :description => "Fred's Portfolio" } }
  let(:id_list) { [] }
  let(:block_access_obj) { instance_double(ManageIQ::API::Common::RBAC::Access, :accessible? => false) }
  let(:graphql_query) { '{ portfolios { id name } }' }
  let(:graphql_body) { { 'query' => graphql_query } }

  describe "GET /portfolios" do
    context "no permission to read portfolios" do
      it "no access" do
        allow(ManageIQ::API::Common::RBAC::Access).to receive(:new).with('portfolios', 'read').and_return(block_access_obj)
        allow(ManageIQ::API::Common::RBAC::Roles).to receive(:assigned_role?).with('Catalog Administrator').and_return(false)
        allow(block_access_obj).to receive(:process).and_return(block_access_obj)
        get "#{api('1.0')}/portfolios/#{portfolio1.id}", :headers => default_headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "Catalog Administrator can see all" do
      before do
        allow(ManageIQ::API::Common::RBAC::Roles).to receive(:assigned_role?).with('Catalog Administrator').and_return(true)
      end

      it 'specific portfolio' do
        get "#{api('1.0')}/portfolios/#{portfolio1.id}", :headers => default_headers
        expect(response).to have_http_status(:ok)
      end

      it 'all portfolios' do
        get "#{api('1.0')}/portfolios", :headers => default_headers
        expect(response).to have_http_status(:ok)
        expect(json['data'].collect { |x| x['id'] }).to match_array([portfolio1.id.to_s, portfolio2.id.to_s])
      end
    end

    context "permission to read specific portfolios" do
      let(:id_list) { [portfolio1.id.to_s] }

      before do
        allow(ManageIQ::API::Common::RBAC::Access).to receive(:new).with('portfolios', 'read').and_return(access_obj)
        allow(ManageIQ::API::Common::RBAC::Roles).to receive(:assigned_role?).with('Catalog Administrator').and_return(false)
        allow(access_obj).to receive(:process).and_return(access_obj)
      end

      it 'ok' do
        get "#{api('1.0')}/portfolios/#{portfolio1.id}", :headers => default_headers
        expect(response).to have_http_status(:ok)
      end

      it 'forbidden' do
        get "#{api('1.0')}/portfolios/#{portfolio2.id}", :headers => default_headers
        expect(response).to have_http_status(:forbidden)
      end

      context "via graphql" do
        let(:graphql_query) { "{ portfolios(id: #{portfolio1.id}) { id name } }" }
        it 'ok' do
          post "#{api('1.0')}/graphql", :headers => default_headers, :params => graphql_body
          expect(response).to have_http_status(:ok)
          expect(json['data']['portfolios'][0]['name']).to eq(portfolio1.name)
        end
      end

      context "via graphql fetch an inaccessible portfolio" do
        let(:graphql_query) { "{ portfolios(id: #{portfolio2.id}) { id name } }" }
        it 'gives an empty body' do
          post "#{api('1.0')}/graphql", :headers => default_headers, :params => graphql_body
          expect(response).to have_http_status(:ok)
          expect(json['data']['portfolios']).to be_empty
        end
      end
    end
  end

  describe "POST /graphql" do
    context "no permission to read portfolios" do
      it "no access" do
        allow(ManageIQ::API::Common::RBAC::Access).to receive(:new).with('portfolios', 'read').and_return(block_access_obj)
        allow(ManageIQ::API::Common::RBAC::Roles).to receive(:assigned_role?).with('Catalog Administrator').and_return(false)
        allow(block_access_obj).to receive(:process).and_return(block_access_obj)
        post "#{api('1.0')}/graphql", :headers => default_headers, :params => graphql_body
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
