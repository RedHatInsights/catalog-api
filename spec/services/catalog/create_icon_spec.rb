describe Catalog::CreateIcon, :type => :service do
  let(:subject) { described_class.new(params) }

  shared_examples_for "#process icon after being created" do
    let(:icon) { subject.process.icon }

    it "creates the proper fields on the icon" do
      expect(icon.source_ref).to eq params[:source_ref]
      expect(icon.source_id).to eq params[:source_id]
    end

    it "points to the right image" do
      expect(icon.image.extension).to eq Magick::Image.from_blob(Base64.decode64(image_params[:content])).first.format
      expect(icon.image.content).to eq image_params[:content]
    end

    it "deletes the image related key from the params hash" do
      icon
      expect(params.key?(:content)).to be_falsey
    end
  end

  describe "#process" do
    let!(:base_image) { Image.create(:content => Base64.strict_encode64(File.read(Rails.root.join("spec", "support", "images", "ocp_logo.svg")))) }
    let(:portfolio_item) { create(:portfolio_item) }

    context "when there is not an image record" do
      let(:image_params) { {:content => Base64.strict_encode64(File.read(Rails.root.join("spec", "support", "images", "miq_logo.svg")))} }
      let(:params) { {:source_ref => "icon_ref", :source_id => "source_id", :portfolio_item => portfolio_item}.merge(image_params) }

      it "creates a new image record" do
        expect(subject.process.icon.image_id).to_not eq base_image.id
      end

      it_behaves_like "#process icon after being created"
    end

    context "when there is an image record" do
      let(:image_params) { {:content => Base64.strict_encode64(File.read(Rails.root.join("spec", "support", "images", "ocp_logo_dupe.svg")))} }
      let(:params) { {:source_ref => "icon_ref", :source_id => "source_id", :portfolio_item => portfolio_item}.merge(image_params) }

      it "uses the existing record" do
        expect(subject.process.icon.image_id).to eq base_image.id
      end

      it_behaves_like "#process icon after being created"
    end
  end
end
