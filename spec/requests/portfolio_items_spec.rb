include RequestSpecHelper
describe 'PortfolioItems API' do

  let!(:portfolio_item)       { create(:portfolio_item) }
  let(:portfolio_item_id)     { portfolio_item.id }
  let(:tenant)                { create(:tenant, :with_external_tenant) }

  # Encoded Header: { 'identity' => { 'is_org_admin':false, 'org_id':111 } }
  let(:user_encode_key_with_tenant) { { 'x-rh-auth-identity': 'eyJpZGVudGl0eSI6eyJpc19vcmdfYWRtaW4iOmZhbHNlLCJvcmdfaWQiOiIxMTEifX0=' } }
  # Encoded Header: { 'identity' => { 'is_org_admin':true, 'org_id':111 } }
  let(:admin_encode_key_with_tenant) { { 'x-rh-auth-identity': 'eyJpZGVudGl0eSI6eyJpc19vcmdfYWRtaW4iOnRydWUsIm9yZ19pZCI6MTExfX0=' } }

  # Gah, Acts as Tenancy is killing me
  #before { allow_any_instance_of(ApplicationController).to receive(:set_current_tenant).and_return(tenant) }
  %w(admin user).each do |tag|
    describe "GET #{tag} tagged #{api_version}/portfolio_items" do
      before do
        get "#{api_version}/portfolio_items", headers: send("#{tag}_encode_key_with_tenant")
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

  describe 'admin tagged #{api_version}/portfolio_items', :type => :routing  do
    let(:valid_attributes) { { name: 'rspec 1', description: 'rspec 1 description' } }
    context 'with wrong header' do
      it 'returns a 404' do
        expect(:post => "#{api_version}/portfolio_items").not_to be_routable
      end
    end
  end

  describe 'POST admin tagged #{api_version}/portfolio_items' do
    let(:valid_attributes) { { name: 'rspec 1', description: 'rspec 1 description', service_offering_ref: '10' } }
    context 'when portfolio attributes are valid' do
      before { post "#{api_version}/portfolio_items", params: valid_attributes, headers: admin_encode_key_with_tenant }

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns the new portfolio' do
        expect(json['name']).to eq valid_attributes[:name]
      end
    end
  end
end
