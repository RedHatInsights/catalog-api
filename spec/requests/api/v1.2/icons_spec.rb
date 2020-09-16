describe "v1.2 - IconsRequests", :type => [:request, :v1x2] do
  let!(:portfolio_item) { create(:portfolio_item) }
  let!(:portfolio) { create(:portfolio) }

  let!(:icon) do
    create(:icon, :image => image, :restore_to => portfolio_item).tap do |icon|
      icon.restore_to.update!(:icon_id => icon.id)
    end
  end
  let!(:portfolio_icon) do
    create(:icon, :image => image, :restore_to => portfolio).tap do |icon|
      icon.restore_to.update!(:icon_id => icon.id)
    end
  end

  let(:image) { create(:image) }

  describe "#raw_icon" do
    context "when the icon exists" do
      it "returns the icon with cache_id param from /portfolios/{portfolio_id}/icon?cache_id=123" do
        get "#{api_version}/portfolios/#{portfolio.id}/icon?cache_id=123", :headers => default_headers

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq "image/svg+xml"
      end
    end
  end
end
