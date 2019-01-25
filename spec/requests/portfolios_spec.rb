describe 'Portfolios API' do
  include RequestSpecHelper
  include ServiceSpecHelper

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

        it 'returns all portfolio requests' do
          expect(json).not_to be_empty
          expect(json['id']).to eq(portfolio_id)
        end
      end
    end

    describe "GET #{tag} tagged /portfolios?portfolio_id=''" do
      before do
        get "#{api}/portfolios?portfolio_id=''", :headers => send("#{tag}_headers")
      end

      context 'empty parameter' do
        it 'returns status code 422' do
          expect(response).to have_http_status(422)
        end
      end
    end

    describe "GET #{tag} tagged /portfolios?identity%5Bportfolio_id%5D=" do
      before do
        get "#{api}/portfolios?identity%5Bportfolio_id%5D=", :headers => send("#{tag}_headers")
      end

      context 'empty nested parameter' do
        it 'returns status code 422' do
          expect(response).to have_http_status(422)
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

    describe "GET #{tag} tagged /portfolios/:portfolio_id/portfolio_items/:portfolio_item_id" do
      before do
        get "#{api}/portfolios/#{portfolio_id}/portfolio_items/#{portfolio_item_id}", :headers => send("#{tag}_headers")
      end

      it 'returns an associated portfolio_item for a specific portfolio' do
        expect(json).not_to be_empty
        expect(json['id']).to eq portfolio_item_id
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

    context 'when :portfolio_id is valid' do
      before do
        delete "#{api}/portfolios/#{portfolio_id}", :headers => admin_headers, :params => valid_attributes
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
    end
  end
end
