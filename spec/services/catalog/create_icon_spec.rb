describe Catalog::CreateIcon, :type => :service do
  let(:subject) { described_class.new(params) }

  shared_examples_for "#process icon after being created" do
    let(:icon) { subject.process.icon }

    it "creates the proper fields on the icon" do
      expect(icon.source_ref).to eq params[:source_ref]
      expect(icon.source_id).to eq params[:source_id]
    end

    it "points to the right image" do
      expect(icon.image.extension).to eq Magick::Image.from_blob(File.read(image_params[:content].tempfile)).first.format
      expect(icon.image.content).to eq Base64.strict_encode64(File.read(image_params[:content].tempfile))
    end

    it "deletes the image related key from the params hash" do
      icon
      expect(params.key?(:content)).to be_falsey
    end
  end

  shared_examples_for "#process handling generic object" do
    context "when there is not an image record" do
      let(:image_params) { {:content => form_upload_test_image("miq_logo.svg")} }

      it "creates a new image record" do
        expect(subject.process.icon.image_id).to_not eq base_image.id
      end

      it_behaves_like "#process icon after being created"
    end

    context "when there is an image record" do
      let(:image_params) { {:content => form_upload_test_image("ocp_logo_dupe.svg")} }

      it "uses the existing record" do
        expect(subject.process.icon.image_id).to eq base_image.id
      end

      it_behaves_like "#process icon after being created"
    end

    context "when there is already an icon" do
      let(:image_params) { {:content => form_upload_test_image("ocp_logo.jpg")} }

      before do
        subject.process
        subject.process
        destination.reload
      end

      it "discards the old icon" do
        expect(Icon.with_discarded.discarded.where(:restore_to => destination).count).to eq 1
      end

      it "has an icon" do
        expect(destination.icon).to be_truthy
      end
    end
  end

  describe "#process" do
    let!(:base_image) { Image.create(:content => Base64.strict_encode64(File.read(Rails.root.join("spec", "support", "images", "ocp_logo.svg")))) }
    let(:params) { {:source_ref => "icon_ref", :source_id => "source_id"}.merge(image_params).merge(destination_params) }

    context "when adding an icon to a portfolio item" do
      let(:destination) { create(:portfolio_item) }
      let(:destination_params) { {:portfolio_item_id => destination.id} }

      it_behaves_like "#process handling generic object"
    end

    context "when adding an icon to a portfolio" do
      let(:destination) { create(:portfolio) }
      let(:destination_params) { {:portfolio_id => destination.id} }

      it_behaves_like "#process handling generic object"
    end
  end
end
