describe 'Portfolios Delete Access RBAC API', :type => [:request, :v1] do
  let!(:portfolio1) { create(:portfolio) }
  let!(:portfolio2) { create(:portfolio) }
  let(:rbac_access) { instance_double(Catalog::RBAC::Access) }

  describe "DELETE /portfolios" do
    before do
      allow(Catalog::RBAC::Access).to receive(:new).and_return(rbac_access)
    end

    context "catalog user is an admin" do
      before do
        allow(rbac_access).to receive(:admin_check).and_return(true)
      end

      it "allows deletion of any portfolio" do
        delete "#{api_version}/portfolios/#{portfolio1.id}", :headers => default_headers
        expect(response).to have_http_status(:ok)

        delete "#{api_version}/portfolios/#{portfolio2.id}", :headers => default_headers
        expect(response).to have_http_status(:ok)
      end
    end

    context "catalog user is not an admin" do
      before do
        allow(rbac_access).to receive(:admin_check).and_return(false)
      end

      it "fails to delete any portfolio" do
        delete "#{api_version}/portfolios/#{portfolio1.id}", :headers => default_headers
        expect(response).to have_http_status(:forbidden)

        delete "#{api_version}/portfolios/#{portfolio2.id}", :headers => default_headers
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
