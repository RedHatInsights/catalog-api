describe Catalog::CreateIcon do
  shared_examples_for "#process icon after being created" do
    let(:icon) { subject.icon }

    it "creates the proper fields on the icon" do
      expect(icon.source_ref).to eq params[:source_ref]
      expect(icon.source_id).to eq params[:source_id]
    end

    it "points to the right image" do
      expect(icon.image.extension).to eq image_params[:filename].split(".").last
      expect(icon.image.content).to eq image_params[:content]
    end

    it "deletes the image related keys from the params hash" do
      icon
      expect(params.key?(:filename)).to be_falsey
      expect(params.key?(:content)).to be_falsey
    end
  end

  let!(:base_image) do
    create(:image,
           :extension => "svg",
           :content   => "<svg rel=\"stylesheet\">The OG Image</svg>")
  end

  let(:subject) { described_class.new(params).process }

  describe "#process" do
    context "when there is not an image record" do
      let(:image_params) { {:filename => "new_image.svg", :content => "<svg rel=\"stylesheet\">A Wild Image Appeared!</svg>"} }
      let(:params) { {:source_ref => "icon_ref", :source_id => "source_id" }.merge(image_params) }

      it "creates a new image record" do
        expect(subject.icon.image_id).to_not eq base_image.id
      end

      it_behaves_like "#process icon after being created"
    end

    context "when there is an image record" do
      let(:image_params) { {:filename => "og_image.svg", :content => "<svg rel=\"stylesheet\">The OG Image</svg>"} }
      let(:params) { {:source_ref => "icon_ref", :source_id => "source_id"}.merge(image_params) }

      it "uses the existing record" do
        expect(subject.icon.image_id).to eq base_image.id
      end

      it_behaves_like "#process icon after being created"
    end
  end
end
