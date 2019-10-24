describe Catalog::DuplicateImage, :type => :service do
  let(:subject) { described_class.new(new_image) }

  shared_examples_for "#process when there is not a duplicate image" do
    let(:filename) { "miq_logo.#{extension}" }

    it "returns a new image id" do
      expect(subject.process.image_id).to_not eq base_image.id
    end
  end

  shared_examples_for "#process when uploading a duplicate image" do
    let(:filename) { "ocp_logo_dupe.#{extension}" }

    it "returns the base_image image id" do
      expect(subject.process.image_id).to eq base_image.id
    end
  end

  describe "#process" do
    let!(:base_image) { Image.create(:content => Base64.encode64(File.read(Rails.root.join("spec", "support", "images", "ocp_logo.#{extension}")))) }
    let(:new_image) { Image.new(:content => Base64.encode64(File.read(Rails.root.join("spec", "support", "images", filename)))) }

    context "PNG Images" do
      let(:extension) { "png" }
      it_behaves_like "#process when there is not a duplicate image"
      it_behaves_like "#process when uploading a duplicate image"
    end

    context "JPG Images" do
      let(:extension) { "jpg" }
      it_behaves_like "#process when there is not a duplicate image"
      it_behaves_like "#process when uploading a duplicate image"
    end

    context "SVG Images" do
      let(:extension) { "svg" }
      it_behaves_like "#process when there is not a duplicate image"
      it_behaves_like "#process when uploading a duplicate image"
    end
  end
end
