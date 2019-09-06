describe "IconsRequests", :type => :request do
  let!(:portfolio_item) { create(:portfolio_item) }
  let!(:icon) { create(:icon, :image => image, :portfolio_item => portfolio_item) }

  let(:image) { create(:image) }

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
    let!(:ocp_jpg_image) do
      create(:image,
             :content => Base64.strict_encode64(File.read(Rails.root.join("spec", "support", "images", "ocp_logo.jpg"))),
             :extension => "JPEG"
            )
    end
    let!(:ocp_png_image) do
      create(:image,
             :content => Base64.strict_encode64(File.read(Rails.root.join("spec", "support", "images", "ocp_logo.png"))),
             :extension => "PNG"
            )
    end

    before { post "#{api}/icons", :params => params, :headers => default_headers }

    context "when providing proper parameters" do
      let(:params) { {:content => image.content, :source_id => "27", :source_ref => "icon_ref", :portfolio_item_id => portfolio_item.id} }

      it "returns a 200" do
        expect(response).to have_http_status(:ok)
      end

      it "returns the created icon" do
        expect(json["image_id"]).to be_truthy
        expect(json["source_id"]).to eq params[:source_id]
      end
    end

    context "when uploading a duplicate svg icon" do
      let(:params) { {:content => image.content, :source_id => "27", :source_ref => "icon_ref", :portfolio_item_id => portfolio_item.id} }

      it "uses the reference from the one that is already there" do
        expect(json["image_id"]).to eq image.id.to_s
      end
    end

    context "when uploading a duplicate png icon" do
      let(:params) do
        {
          :content    => Base64.strict_encode64(File.read(Rails.root.join("spec", "support", "images", "ocp_logo_dupe.png"))),
          :source_id  => "29",
          :source_ref => "icon_ref",
          :portfolio_item_id => portfolio_item.id
        }
      end

      it "uses the already-existing image" do
        expect(json["image_id"]).to eq ocp_png_image.id.to_s
      end
    end

    context "when uploading a duplicate jpg icon" do
      let(:params) do
        {
          :content    => Base64.strict_encode64(File.read(Rails.root.join("spec", "support", "images", "ocp_logo_dupe.jpg"))),
          :source_id  => "29",
          :source_ref => "icon_ref",
          :portfolio_item_id => portfolio_item.id
        }
      end

      it "uses the already-existing image" do
        expect(json["image_id"]).to eq ocp_jpg_image.id.to_s
      end
    end

    context "when passing in improper parameters" do
      let(:params) { { :not_the_right_param => "whereami" } }

      it "throws a 422" do
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when uploading a png" do
      let(:params) do
        {
          :content    => Base64.strict_encode64(File.read(Rails.root.join("spec", "support", "images", "miq_logo.png"))),
          :source_id  => "29",
          :source_ref => "icon_ref"
        }
      end

      it "makes a new image and icon" do
        expect(json["image_id"]).to_not eq image.id
      end
    end

    context "when uploading a jpg" do
      let(:params) do
        {
          :content    => Base64.strict_encode64(File.read(Rails.root.join("spec", "support", "images", "miq_logo.jpg"))),
          :source_id  => "29",
          :source_ref => "icon_ref"
        }
      end

      it "makes a new image and icon" do
        expect(json["image_id"]).to_not eq image.id
      end
    end
  end

  describe "#update" do
    let(:params) { {:content => Base64.strict_encode64(File.read(Rails.root.join("spec", "support", "images", "miq_logo.svg"))) } }

    before do
      patch "#{api}/icons/#{icon.id}", :params => params, :headers => default_headers
      icon.reload
    end

    it "returns a 200" do
      expect(response).to have_http_status(:ok)
    end

    it "updates the fields passed in" do
      expect(icon.image.content).to eq params[:content]
    end

    it "updated to a new image record" do
      expect(icon.image_id).to_not eq image.id
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
      it "returns not found" do
        get "#{api}/portfolio_items/0/icon", :headers => default_headers

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "#override_icon" do
    let!(:new_icon) { create(:icon) }
    before { post "#{api}/icons/#{new_icon.id}/override", :params => { :portfolio_item_id => portfolio_item.id }, :headers => default_headers }

    it "returns the new icon" do
      expect(json["id"]).to eq new_icon.id.to_s
    end

    it "overrides the icon" do
      expect(portfolio_item.icons.first.id).to eq new_icon.id
    end

    it "soft-deletes the old one" do
      expect { Icon.find(icon.id) }.to raise_exception(ActiveRecord::RecordNotFound)
      expect(Icon.with_discarded.find(icon.id)).to be_truthy
    end
  end
end
