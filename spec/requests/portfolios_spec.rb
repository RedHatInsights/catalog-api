describe 'Portfolios API' do
  before { disable_tenancy }

  let!(:portfolio)            { create(:portfolio) }
  let!(:portfolio_item)       { create(:portfolio_item) }
  let!(:portfolio_items)      { portfolio.portfolio_items << portfolio_item }
  let(:portfolio_id)          { portfolio.id }
  let(:portfolio_item_id)     { portfolio_items.first.id }
  let(:new_portfolio_item_id) { portfolio_item.id }
  let(:tenant)                { create(:tenant, :with_external_tenant) }

  %w(admin user).each do |tag|
    describe "GET #{tag} tagged /portfolios/:portfolio_id" do
      before do
        get "#{api}/portfolios/#{portfolio_id}", :headers => send("#{tag}_headers")
      end

      context 'when portfolios exist' do
        it 'returns status code 200' do
          expect(response).to have_http_status(200)
        end

        it 'returns portfolio requested' do
          expect(json).not_to be_empty
          expect(json['id']).to eq(portfolio_id)
        end
      end
    end

    describe "GET #{tag} v0.1 tagged /portfolios/:portfolio_id" do
      before do
        get "#{api('0.1')}/portfolios/#{portfolio_id}", :headers => send("#{tag}_headers")
      end

      context 'when portfolios exist' do
        it 'returns status code 200' do
          expect(response).to have_http_status(200)
        end

        it 'returns portfolio requested' do
          expect(json).not_to be_empty
          expect(json['id']).to eq(portfolio_id)
        end
      end
    end

    describe "GET #{tag} tagged /portfolios/:portfolio_id/portfolio_items" do
      before do
        get "#{api}/portfolios/#{portfolio_id}/portfolio_items", :headers => send("#{tag}_headers")
      end

      it 'returns all associated portfolio_items' do
        expect(json).not_to be_empty
        expect(json.count).to eq 1
        portfolio_item_ids = portfolio_items.map(&:id).sort
        expect(json.map { |x| x['id'] }.sort).to eq portfolio_item_ids
      end
    end

    describe "GET #{tag} tagged /portfolios/:portfolio_id/portfolio_items v0.1" do
      before do
        get "/api/v0.1/portfolios/#{portfolio_id}/portfolio_items", :headers => send("#{tag}_headers")
      end

      it 'returns all associated portfolio_items' do
        expect(json).not_to be_empty
        expect(json['data'].count).to eq 1
        portfolio_item_ids = portfolio_items.map(&:id).sort
        expect(json['data'].map { |x| x['id'] }.sort).to eq portfolio_item_ids
      end
    end

    describe "GET #{tag} tagged /portfolios_items/:portfolio_item_id" do
      before do
        get "#{api}/portfolio_items/#{portfolio_item_id}", :headers => send("#{tag}_headers")
      end

      it 'returns an associated portfolio_item for a specific portfolio' do
        expect(json).not_to be_empty
        expect(json['id']).to eq portfolio_item_id
      end
    end

    describe "GET #{tag} tagged /portfolios_items/:portfolio_item_id v0.1" do
      before do
        get "#{api('0.1')}/portfolio_items/#{portfolio_item_id}", :headers => send("#{tag}_headers")
      end

      it 'returns an associated portfolio_item for a specific portfolio' do
        expect(json).not_to be_empty
        expect(json['id']).to eq portfolio_item_id
      end
    end

    describe "POST admin tagged /portfolios/:portfolio_id/portfolio_items" do
      let(:portfolio) { create(:portfolio) }
      let(:portfolio_item) { create(:portfolio_item) }
      let(:params) { {:portfolio_item_id => portfolio_item.id} }
      before do
        post "#{api}/portfolios/#{portfolio.id}/portfolio_items", :params => params, :headers => send("#{tag}_headers")
      end

      it 'returns a 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns the portfolio_item which now points back to the portfolio' do
        expect(json.size).to eq 1
        expect(json.first['portfolio_id']).to eq portfolio.id
      end
    end

    describe "POST admin tagged /portfolios/:portfolio_id/portfolio_items v0.1" do
      let(:portfolio) { create(:portfolio) }
      let(:portfolio_item) { create(:portfolio_item) }
      let(:params) { {:portfolio_item_id => portfolio_item.id} }
      before do
        post "#{api('0.1')}/portfolios/#{portfolio.id}/portfolio_items", :params => params, :headers => send("#{tag}_headers")
      end

      it 'returns a 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns the portfolio_item which now points back to the portfolio' do
        expect(json.size).to eq 1
        expect(json.first['portfolio_id']).to eq portfolio.id
      end
    end

    describe "GET #{tag} tagged /portfolios" do
      before do
        get "#{api}/portfolios", :headers => send("#{tag}_headers")
      end

      context 'when portfolios exist' do
        it 'returns status code 200' do
          expect(response).to have_http_status(200)
        end

        it 'returns all portfolio requests' do
          expect(json.size).to eq(1)
        end
      end
    end

    describe "GET #{tag} tagged /portfolios v0.1" do
      before do
        get "/api/v0.1/portfolios", :headers => send("#{tag}_headers")
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
  end

  describe 'admin tagged /portfolios', :type => :routing do
    let(:valid_attributes) { { :name => 'rspec 1', :description => 'rspec 1 description' } }
    context 'with wrong header' do
      it 'returns a 404' do
        expect(:post => "/portfolios").not_to be_routable
      end
    end
  end

  describe 'DELETE admin tagged /portfolios/:portfolio_id' do
    let(:valid_attributes) { { :name => 'PatchPortfolio', :description => 'description for patched portfolio' } }

    context 'when discarding a portfolio' do
      before do
        delete "#{api}/portfolios/#{portfolio_id}", :headers => admin_headers, :params => valid_attributes
      end

      it 'deletes the record' do
        expect(response).to have_http_status(204)
      end

      it 'sets the discarded_at column' do
        expect(Portfolio.find_by(:id => portfolio_id).discarded_at).to_not be_nil
      end

      it 'allows adding portfolios with the same name when one is discarded' do
        post "#{api}/portfolios", :headers => admin_headers, :params => valid_attributes

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when :portfolio_id is valid v0.1' do
      before do
        delete "#{api('0.1')}/portfolios/#{portfolio_id}", :headers => admin_headers, :params => valid_attributes
      end

      it 'deletes the record' do
        expect(response).to have_http_status(204)
      end
    end
  end

  describe 'PATCH admin tagged /portfolios/:portfolio_id' do
    let(:valid_attributes) { { :name => 'PatchPortfolio', :description => 'description for patched portfolio' } }
    let(:invalid_attributes) { { :fred => 'nope', :bob => 'bob portfolio' } }
    context 'when patched portfolio is valid' do
      before do
        patch "#{api}/portfolios/#{portfolio_id}", :headers => admin_headers, :params => valid_attributes
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

    context 'when patched portfolio is valid v0.1' do
      before do
        patch "#{api('0.1')}/portfolios/#{portfolio_id}", :headers => admin_headers, :params => valid_attributes
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

    context 'when patched portfolio params are invalid' do
      before do
        patch "#{api}/portfolios/#{portfolio_id}", :headers => admin_headers, :params => invalid_attributes
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns an updated portfolio object' do
        expect(json).not_to be_empty
        expect(json).to be_a Hash
        expect(json['name']).to_not eq invalid_attributes[:name]
      end
    end

    context 'when patched portfolio params are invalid v0.1' do
      before do
        patch "#{api('0.1')}/portfolios/#{portfolio_id}", :headers => admin_headers, :params => invalid_attributes
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns an updated portfolio object' do
        expect(json).not_to be_empty
        expect(json).to be_a Hash
        expect(json['name']).to_not eq invalid_attributes[:name]
      end
    end
  end

  describe 'POST admin tagged /portfolios' do
    let(:valid_attributes) { { :name => 'rspec 1', :description => 'rspec 1 description' } }
    context 'when portfolio attributes are valid' do
      before { post "#{api}/portfolios", :params => valid_attributes, :headers => admin_headers }

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns the new portfolio' do
        expect(json['name']).to eq valid_attributes[:name]
      end

      it 'returns a status code 422 when trying to create with the same name' do
        post "#{api}/portfolios", :params => valid_attributes, :headers => admin_headers

        expect(response).to have_http_status(422)
      end
    end

    context 'when portfolio attributes are valid v0.1' do
      before { post "#{api('0.1')}/portfolios", :params => valid_attributes, :headers => admin_headers }

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns the new portfolio' do
        expect(json['name']).to eq valid_attributes[:name]
      end

      it 'returns a status code 422 when trying to create with the same name' do
        post "#{api('0.1')}/portfolios", :params => valid_attributes, :headers => admin_headers

        expect(response).to have_http_status(422)
      end
    end
  end
end
