describe "v1.0 - IconsRequests", :type => [:request, :v1] do
  let(:api_version) { api(1.0) }
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

  describe "#show" do
    before { get "#{api_version}/icons/#{icon.id}", :headers => default_headers }

    it "returns a 200" do
      expect(response).to have_http_status(:ok)
    end

    it "returns the icon specified" do
      expect(json["id"]).to eq icon.id.to_s
    end
  end

  describe "#destroy" do
    before { delete "#{api_version}/icons/#{icon.id}", :headers => default_headers }

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
             :content   => Base64.strict_encode64(File.read(Rails.root.join("spec", "support", "images", "ocp_logo.jpg"))),
             :extension => "JPEG")
    end
    let!(:ocp_png_image) do
      create(:image,
             :content   => Base64.strict_encode64(File.read(Rails.root.join("spec", "support", "images", "ocp_logo.png"))),
             :extension => "PNG")
    end

    before do
      post "#{api_version}/icons", :params => params, :headers => default_headers, :as => :form
    end

    context "when providing proper parameters" do
      let(:params) { {:content => form_upload_test_image("ocp_logo.svg"), :portfolio_item_id => portfolio_item.id} }

      it "returns a 200" do
        expect(response).to have_http_status(:ok)
      end

      it "returns the created icon" do
        expect(json["image_id"]).to be_truthy
      end
    end

    context "when uploading a duplicate svg icon" do
      let(:params) { {:content => form_upload_test_image("ocp_logo.svg"), :portfolio_item_id => portfolio_item.id} }

      it "uses the reference from the one that is already there" do
        expect(json["image_id"]).to eq image.id.to_s
      end
    end

    context "when uploading a duplicate png icon" do
      let(:params) do
        {
          :content           => form_upload_test_image("ocp_logo_dupe.png"),
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
          :content           => form_upload_test_image("ocp_logo_dupe.jpg"),
          :portfolio_item_id => portfolio_item.id
        }
      end

      it "uses the already-existing image" do
        expect(json["image_id"]).to eq ocp_jpg_image.id.to_s
      end
    end

    context "when passing in improper parameters" do
      let(:params) { { :not_the_right_param => "whereami" } }

      it "throws a 400" do
        expect(response).to have_http_status(:bad_request)
      end
    end

    context "when not passing in a portfolio or portfolio_item id" do
      let(:params) do
        {:content => Base64.strict_encode64(File.read(Rails.root.join("spec", "support", "images", "miq_logo.png")))}
      end

      it "throws a 400" do
        expect(response).to have_http_status(:bad_request)
      end
    end

    context "when uploading a png" do
      let(:params) do
        {:content => Base64.strict_encode64(File.read(Rails.root.join("spec", "support", "images", "miq_logo.png")))}
      end

      it "makes a new image and icon" do
        expect(json["image_id"]).to_not eq image.id
      end
    end

    context "when uploading a jpg" do
      let(:params) do
        {:content => Base64.strict_encode64(File.read(Rails.root.join("spec", "support", "images", "miq_logo.jpg")))}
      end

      it "makes a new image and icon" do
        expect(json["image_id"]).to_not eq image.id
      end
    end
  end

  describe "#update" do
    let(:params) { {:content => form_upload_test_image("miq_logo.svg") } }

    before do
      patch "#{api_version}/icons/#{icon.id}", :params => params, :headers => default_headers, :as => :form
      icon.reload
    end

    it "returns a 200" do
      expect(response).to have_http_status(:ok)
    end

    it "updates the fields passed in" do
      expect(icon.image.content).to eq Base64.strict_encode64(File.read(Rails.root.join("spec", "support", "images", "miq_logo.svg")))
    end

    it "updated to a new image record" do
      expect(icon.image_id).to_not eq image.id
    end
  end

  describe "#raw_icon" do
    context "when the icon exists" do
      it "/portfolio_items/{portfolio_item_id}/icon returns the icon" do
        get "#{api_version}/portfolio_items/#{portfolio_item.id}/icon", :headers => default_headers

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq "image/svg+xml"
      end

      it "/portfolios/{portfolio_id}/icon returns the icon" do
        get "#{api_version}/portfolios/#{portfolio.id}/icon", :headers => default_headers

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq "image/svg+xml"
      end

      it "/icons/{icon_id}/icon_data returns the icon" do
        get "#{api_version}/icons/#{icon.id}/icon_data", :headers => default_headers
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq "image/svg+xml"
      end
    end

    context "when the icon does not exist" do
      it "/portfolio_items/{id}/icon returns no content" do
        get "#{api_version}/portfolio_items/0/icon", :headers => default_headers

        expect(response).to have_http_status(:no_content)
      end

      it "/icons/{id}/icon_data returns no content" do
        get "#{api_version}/icons/0/icon_data", :headers => default_headers

        expect(response).to have_http_status(:no_content)
      end
    end
  end
end
