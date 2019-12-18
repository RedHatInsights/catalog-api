describe 'Portfolios API' do
  around do |example|
    bypass_rbac do
      example.call
    end
  end

  let!(:portfolio)       { create(:portfolio) }
  let!(:portfolio_item)  { create(:portfolio_item, :portfolio => portfolio) }
  let!(:portfolio_items) { portfolio.portfolio_items << portfolio_item }
  let(:portfolio_id)     { portfolio.id }

  describe "GET /portfolios/:portfolio_id" do
    before do
      get "#{api}/portfolios/#{portfolio_id}", :headers => default_headers
    end

    context 'when portfolios exist' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns portfolio requested' do
        expect(json).not_to be_empty
        expect(json['id']).to eq(portfolio_id.to_s)
        expect(json['created_at']).to eq(portfolio.created_at.iso8601)
      end
    end

    context 'when the portfolio does not exist' do
      let(:portfolio_id) { 0 }

      it "cannot be requested" do
        expect(response).to have_http_status(404)
      end
    end
  end

  describe "GET v1.0 /portfolios/:portfolio_id" do
    before do
      get "#{api}/portfolios/#{portfolio_id}", :headers => default_headers
    end

    context 'when portfolios exist' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns portfolio requested' do
        expect(json).not_to be_empty
        expect(json['id']).to eq(portfolio_id.to_s)
      end
    end
  end

  describe "GET /portfolios" do
    context "without filter" do
      before do
        get "#{api}/portfolios", :headers => default_headers
      end

      context 'when portfolios exist' do
        it 'returns status code 200' do
          expect(response).to have_http_status(200)
        end

        it 'returns all portfolio requests' do
          expect(json['data'].size).to eq(1)
        end
      end
    end

    context "with filter" do
      let!(:portfolio_filter1) { create(:portfolio, :name => "testfilter1") }
      let!(:portfolio_filter2) { create(:portfolio, :name => "testfilter2") }

      it 'returns only the id specified in the filter' do
        get "#{api}/portfolios?filter[id]=#{portfolio_id}", :headers => default_headers

        expect(json["meta"]["count"]).to eq 1
        expect(json["data"].first["id"]).to eq portfolio_id.to_s
      end

      it 'allows filtering by name via regex' do
        get "#{api}/portfolios?filter[name][starts_with]=test", :headers => default_headers

        expect(json["meta"]["count"]).to eq 2

        names = json["data"].each.collect { |item| item["name"] }
        expect(names).to match_array [portfolio_filter1.name, portfolio_filter2.name]
      end
    end
  end

  describe '/portfolios', :type => :routing do
    let(:valid_attributes) { { :name => 'rspec 1', :description => 'rspec 1 description' } }
    context 'with wrong header' do
      it 'returns a 404' do
        expect(:post => "/portfolios").not_to be_routable
      end
    end
  end

  describe 'DELETE /portfolios/:portfolio_id' do
    let(:valid_attributes) { { :name => 'PatchPortfolio', :description => 'description for patched portfolio' } }

    context 'when discarding a portfolio' do
      before do
        delete "#{api}/portfolios/#{portfolio_id}", :headers => default_headers, :params => valid_attributes
      end

      it 'deletes the record' do
        expect(response).to have_http_status(:ok)
      end

      it 'sets the discarded_at column' do
        expect(Portfolio.with_discarded.find_by(:id => portfolio_id).discarded_at).to_not be_nil
      end

      it 'allows adding portfolios with the same name when one is discarded' do
        post "#{api}/portfolios", :headers => default_headers, :params => valid_attributes

        expect(response).to have_http_status(:ok)
      end

      it 'returns the restore_key in the body' do
        expect(json["restore_key"]).to eq Digest::SHA1.hexdigest(Portfolio.with_discarded.find(portfolio_id).discarded_at.to_s)
      end
    end

    context "when discarding portfolio_items fails" do
      before do
        allow(Portfolio).to receive(:find).with(portfolio.id.to_s).and_return(portfolio)
        allow(portfolio_item).to receive(:discard).and_return(false)
      end

      it 'reports errors when discarding child portfolio_items fails' do
        delete "#{api}/portfolios/#{portfolio_id}", :headers => default_headers, :params => valid_attributes

        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe "GET /portfolios/:portfolio_id/undelete" do
    let(:restore_key) { Digest::SHA1.hexdigest(portfolio.discarded_at.to_s) }
    let(:params) { { :restore_key => restore_key } }

    before do
      portfolio.discard
    end

    context "when restoring a portfolio" do
      before do
        post "#{api}/portfolios/#{portfolio_id}/undelete", :headers => default_headers, :params => params
      end

      it "returns a 200" do
        expect(response).to have_http_status :ok
      end

      it "returns the restored record" do
        expect(json["id"]).to eq portfolio.id.to_s
        expect(json["name"]).to eq portfolio.name
      end
    end

    context "when restoring a portfolio with the wrong restore key" do
      let(:restore_key) { "MrMaliciousRestoreKey" }

      before do
        portfolio.discard
        post "#{api}/portfolios/#{portfolio_id}/undelete", :headers => default_headers, :params => params
      end

      it "returns a 403" do
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when restoring the portfolio_items fails" do
      before do
        allow(Portfolio).to receive(:with_discarded).and_return(Portfolio)
        allow(Portfolio).to receive(:discarded).and_return(Portfolio)
        allow(Portfolio).to receive(:find).with(portfolio.id.to_s).and_return(portfolio)

        allow(PortfolioItem).to receive(:with_discarded).and_return(PortfolioItem)
        allow(PortfolioItem).to receive(:discarded).and_return([portfolio_item])
        allow(portfolio_item).to receive(:undiscard).and_return(false)
      end

      it 'reports errors when undiscarding the child portfolio_items fails' do
        post "#{api}/portfolios/#{portfolio_id}/undelete", :headers => default_headers, :params => params

        expect(response).to have_http_status(:bad_request)
      end
    end

    context "when restoring a portfolio with portfolio_items that were discarded previously" do
      let!(:second_item) { create(:portfolio_item, :portfolio => portfolio, :discarded_at => 1.minute.ago) }

      before do
        portfolio.discard
      end

      it "only undeletes the one that was discarded at the same time as the portfolio" do
        post "#{api}/portfolios/#{portfolio_id}/undelete", :headers => default_headers, :params => params

        second_item.reload
        expect(second_item.discarded?).to be_truthy
      end
    end
  end

  describe 'PATCH /portfolios/:portfolio_id' do
    let(:valid_attributes) { { :name => 'PatchPortfolio', :description => 'description for patched portfolio' } }
    let(:invalid_attributes) { { :fred => 'nope', :bob => 'bob portfolio' } }
    let(:partial_attributes) { { :name => 'Chef Pisghetti' } }
    context 'when patched portfolio is valid' do
      before do
        patch "#{api}/portfolios/#{portfolio_id}", :headers => default_headers, :params => valid_attributes
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns an updated portfolio object' do
        expect(json).not_to be_empty
        expect(json).to be_a Hash
        expect(json['name']).to eq valid_attributes[:name]
      end
    end

    context 'when patched portfolio has openapi nullable values' do
      let(:nullable_attributes) { { :name => 'PatchPortfolio', :description => 'description for patched portfolio' } }
      before do
        patch "#{api}/portfolios/#{portfolio_id}", :headers => default_headers, :params => nullable_attributes
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns an updated portfolio object' do
        expect(json).not_to be_empty
        expect(json).to be_a Hash
      end
    end

    context 'when patched portfolio params are invalid' do
      before do
        patch "#{api}/portfolios/#{portfolio_id}", :headers => default_headers, :params => invalid_attributes
      end

      it 'returns status code 400' do
        expect(response).to have_http_status(400)
        expect(first_error_detail).to match(/found unpermitted parameters: :fred, :bob/)
      end
    end

    context 'when patched portfolio params are partial' do
      before do
        patch "#{api}/portfolios/#{portfolio_id}", :headers => default_headers, :params => partial_attributes
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
        expect(json['name']).to eq(partial_attributes[:name])
      end
    end
  end

  describe 'POST /portfolios' do
    let(:valid_attributes) { { :name => 'rspec 1', :description => 'rspec 1 description' } }
    context 'when portfolio attributes are valid' do
      before { post "#{api}/portfolios", :params => valid_attributes, :headers => default_headers }

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns the new portfolio' do
        expect(json['name']).to eq valid_attributes[:name]
      end

      it 'returns a status code 400 when trying to create with the same name' do
        post "#{api}/portfolios", :params => valid_attributes, :headers => default_headers

        expect(response).to have_http_status(400)
      end

      it 'stores the username in the owner column' do
        expect(json['owner']).to eq default_username
      end
    end


    shared_examples_for "#shared_test" do
      it "portfolio" do
        with_modified_env :APP_NAME => app_name do
          allow(rs_class).to receive(:call).with(RBACApiClient::GroupApi).and_yield(api_instance)
          allow(Insights::API::Common::RBAC::Service).to receive(:paginate).with(api_instance, :list_groups, {}).and_return(groups)
          post "#{api}/portfolios/#{shared_portfolio.id}/share", :params => attributes, :headers => default_headers
          expect(response).to have_http_status(http_status)
        end
      end
    end

    context 'share' do
      include_context "sharing_objects"
      it_behaves_like "#shared_test"
    end

    context 'bad permissions' do
      include_context "sharing_objects"
      let(:http_status) { '400' }

      context 'invalid verb in permissions' do
        let(:permissions) { %w[something] }
        it_behaves_like "#shared_test"
      end

      context 'invalid group uuids, empty array' do
        let(:group_uuids) { [] }
        # TODO : Waiting for Openapi Parser PR to get merged
        # it_behaves_like "#shared_test"
      end

      context 'invalid group uuids, data type' do
        let(:group_uuids) { "fred" }
        it_behaves_like "#shared_test"
      end
    end

    context 'unshare' do
      include_context "sharing_objects"
      let(:unsharing_attributes) { {:group_uuids => group_uuids, :permissions => permissions} }
      it "portfolio" do
        with_modified_env :APP_NAME => app_name do
          allow(rs_class).to receive(:call).with(RBACApiClient::GroupApi).and_yield(api_instance)
          allow(Insights::API::Common::RBAC::Service).to receive(:paginate).with(api_instance, :list_groups, {}).and_return(groups)
          ace1
          ace2
          ace3
          expect(shared_portfolio.access_control_entries.count).to eq(3)
          post "#{api}/portfolios/#{shared_portfolio.id}/unshare", :params => unsharing_attributes, :headers => default_headers
          shared_portfolio.reload
          expect(response).to have_http_status(204)
          expect(shared_portfolio.access_control_entries.count).to eq(0)
        end
      end
    end

    context 'share_info' do
      include_context "sharing_objects"
      it "portfolio" do
        with_modified_env :APP_NAME => app_name do
          allow(rs_class).to receive(:call).with(RBACApiClient::GroupApi).and_yield(api_instance)
          allow(Insights::API::Common::RBAC::Service).to receive(:paginate).with(api_instance, :list_groups, {}).and_return(groups)
          ace1
          ace2
          ace3
          get "#{api}/portfolios/#{shared_portfolio.id}/share_info", :headers => default_headers
          expect(response).to have_http_status(200)
          expect(json.pluck('group_uuid')).to match_array(group_uuids)
        end
      end
    end

    context "copy without specifying name" do
      before do
        post "#{api}/portfolios/#{portfolio.id}/copy", :headers => default_headers
      end

      it "returns a 200" do
        expect(response).to have_http_status(:ok)
      end

      it "returns a copy of the portfolio" do
        expect(json["id"]).to_not eq portfolio.id
        expect(json["name"]).to match(/^Copy of.*/)
      end

      it "copies the fields completely" do
        expect(json["description"]).to eq portfolio.description
        expect(json["owner"]).to eq portfolio.owner
      end

      it "copies the portfolio item over" do
        item = PortfolioItem.find(Portfolio.find(json["id"]).portfolio_items.first.id)

        expect(item.name).to eq portfolio_item.name
        expect(item.description).to eq portfolio_item.description
        expect(item.owner).to eq portfolio_item.owner
      end
    end

    context "copy when specifying name" do
      let(:params) { { :portfolio_name => "NameyMcNameFace" } }

      before do
        post "#{api}/portfolios/#{portfolio.id}/copy", :params => params, :headers => default_headers
      end

      it "sets the name properly" do
        expect(json["name"]).to eq params[:portfolio_name]
      end
    end
  end

  context "tags" do
    let(:tag_name) { 'Gnocchi' }
    let(:tag_ns) { 'Charkie' }
    let(:tag_value) { 'Hundley' }
    let(:tag_params) do
      { :name      => tag_name,
        :namespace => tag_ns,
        :value     => tag_value }
    end

    shared_examples_for "#tag_add_test" do
      it "add tags for the portfolio" do
        post "#{api}/portfolios/#{portfolio.id}/tags", :headers => default_headers, :params => tag_params
        expect(json['name']).to eq(tag_params[:name])
        expect(json['namespace']).to eq(tag_params[:namespace]) if tag_params.key?(:namespace)
        expect(json['value']).to eq(tag_params[:value]) if tag_params.key?(:value)
        expect(response).to have_http_status(200)
      end
    end

    context "GET /portfolios/{id}/tags" do
      before do
        portfolio.tag_add("test_tag")
      end

      it "returns the tags for the portfolio" do
        get "#{api}/portfolios/#{portfolio.id}/tags", :headers => default_headers

        expect(json["meta"]["count"]).to eq 1
        expect(json["data"].first["name"]).to eq "test_tag"
      end
    end

    context "POST /portfolios/{id}/tag" do
      context 'no namespace and value' do
        let(:tag_params) { { :name => tag_name } }
        it_behaves_like "#tag_add_test"
      end

      context 'no value' do
        let(:tag_params) { { :name => tag_name, :namespace => tag_ns } }
        it_behaves_like "#tag_add_test"
      end

      context 'all in' do
        let(:tag_params) { { :name => tag_name, :namespace => tag_ns, :value => tag_value } }
        it_behaves_like "#tag_add_test"
      end
    end
  end
end
