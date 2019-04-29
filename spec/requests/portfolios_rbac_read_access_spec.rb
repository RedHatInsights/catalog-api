describe 'Portfolios Read Access RBAC API' do
  let(:tenant) { create(:tenant) }
  let!(:portfolio1) { create(:portfolio, :tenant_id => tenant.id) }
  let!(:portfolio2) { create(:portfolio, :tenant_id => tenant.id) }
  let(:access_obj) { instance_double(RBAC::Access, :accessible? => true, :id_list => id_list) }
  let(:valid_attributes) { {:name => 'Fred', :description => "Fred's Portfolio" } }
  let(:id_list) { [] }
  let(:block_access_obj) { instance_double(RBAC::Access, :accessible? => false) }

  describe "GET /portfolios" do
    context "no permission to read portfolios" do
      it "no access" do
        allow(RBAC::Access).to receive(:new).with('portfolios', 'read').and_return(block_access_obj)
        allow(block_access_obj).to receive(:process).and_return(block_access_obj)
        get "#{api('1.0')}/portfolios/#{portfolio1.id}", :headers => default_headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "permission to read specific portfolios" do
      let(:id_list) { [portfolio1.id.to_s] }

      before do
        allow(RBAC::Access).to receive(:new).with('portfolios', 'read').and_return(access_obj)
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
    end
  end
end
