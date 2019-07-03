describe "IconsRequests", :type => :request do
  let(:tenant) { create(:tenant) }
  let!(:portfolio_item) { create(:portfolio_item, :tenant_id => tenant.id) }
  let!(:icon) { create(:icon, :portfolio_item_id => portfolio_item.id, :tenant_id => tenant.id) }

  describe "#show" do
    before { get "#{api}/icons/#{icon.id}", :headers => default_headers }

    it "returns a 200" do
      expect(response).to have_http_status(:ok)
    end

    it "returns the icon specified" do
      expect(json["id"]).to eq icon.id.to_s
    end
  end

  describe "#destroy" do
    before { delete "#{api}/icons/#{icon.id}", :headers => default_headers }

    it "returns a 204" do
      expect(response).to have_http_status(:no_content)
    end

    it "deletes the icon" do
      expect { Icon.find(icon.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "#create" do
    before { post "#{api}/icons", :params => params, :headers => default_headers }

    context "when providing proper parameters" do
      let(:params) { { :data => "<svg rel=\"stylesheet\">thing</svg>", :source_id => "27", :source_ref => "icon_ref" } }

      it "returns a 200" do
        expect(response).to have_http_status(:ok)
      end

      it "returns the created icon" do
        expect(json["data"]).to eq params[:data]
        expect(json["source_id"]).to eq params[:source_id]
      end
    end

    context "when passing in improper parameters" do
      let(:params) { { :not_the_right_param => "whereami" } }

      it "throws a 422" do
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "#update" do
    let(:params) { { :data => "<svg rel=\"new_data\">thing</svg" } }
    before { patch "#{api}/icons/#{icon.id}", :params => params, :headers => default_headers }

    it "returns a 200" do
      expect(response).to have_http_status(:ok)
    end

    it "updates the fields passed in" do
      expect(json["data"]).to eq params[:data]
    end
  end

  describe "#raw_icon" do
    context "when the icon exists" do
      it "/portfolio_items/{portfolio_item_id}/icon returns the icon" do
        get "#{api}/portfolio_items/#{portfolio_item.id}/icon", :headers => default_headers

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq "image/svg+xml"
      end

      it "/icons/{icon_id}/icon_data returns the icon" do
        get "#{api}/icons/#{icon.id}/icon_data", :headers => default_headers
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq "image/svg+xml"
      end
    end

    context "when the icon does not exist" do
      before { icon.update!(:portfolio_item_id => nil) }

      it "returns not found" do
        get "#{api}/portfolio_items/#{portfolio_item.id}/icon", :headers => default_headers

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
