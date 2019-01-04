describe 'PortfolioItems API' do
  include RequestSpecHelper
  include ServiceSpecHelper

  let!(:portfolio_item)       { create(:portfolio_item) }
  let(:portfolio_item_id)     { portfolio_item.id }
  let(:tenant)                { create(:tenant, :with_external_tenant) }

  # Encoded Header: { 'identity' => { 'is_org_admin':false, 'org_id':111 } }
  let(:user_encode_key_with_tenant) { { 'x-rh-auth-identity': 'eyJpZGVudGl0eSI6eyJpc19vcmdfYWRtaW4iOmZhbHNlLCJvcmdfaWQiOiIxMTEifX0=' } }
  # Encoded Header: { 'identity' => { 'is_org_admin':true, 'org_id':111 } }
  let(:admin_encode_key_with_tenant) { { 'x-rh-auth-identity': 'eyJpZGVudGl0eSI6eyJpc19vcmdfYWRtaW4iOnRydWUsIm9yZ19pZCI6MTExfX0=' } }

  %w(admin user).each do |tag|
    describe "GET #{tag} tagged /portfolio_items" do
      before do
        get "#{api}/portfolio_items", headers: send("#{tag}_encode_key_with_tenant")
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

  describe 'admin tagged /portfolio_items', :type => :routing  do
    let(:valid_attributes) { { name: 'rspec 1', description: 'rspec 1 description' } }
    context 'with wrong header' do
      it 'returns a 404' do
        pending("Will work again when headers are checked")
        expect(:post => "#{api}/portfolio_items").not_to be_routable
      end
    end
  end

  describe 'DELETE admin tagged /portfolio_items/:portfolio_item_id' do
    let(:valid_attributes) { { :name => 'PatchPortfolio', :description => 'description for patched portfolio' } }

    context 'when :portfolio_item_id is valid' do
      before do
        delete "#{api}/portfolio_items/#{portfolio_item_id}", :headers => admin_headers, :params => valid_attributes
      end

      it 'deletes the record' do
        expect(response).to have_http_status(204)
      end
    end
  end

  describe 'POST admin tagged /portfolio_items' do
    let(:valid_attributes) { { name: 'rh-mediawiki-apb', description: 'Mediawiki apb implementation', service_offering_ref: '21' } }
    context 'when portfolio attributes are valid' do
      before do
        post "#{api}/portfolio_items", params: valid_attributes, headers: admin_encode_key_with_tenant
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns the new portfolio' do
        expect(json['name']).to eq valid_attributes[:name]
      end
    end
  end
end
