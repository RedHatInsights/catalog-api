describe Catalog::DuplicateImage do
  let(:subject) { described_class.new(new_image).process }

  shared_examples_for "#process when there is not a duplicate image" do
    let(:filename) { "miq_logo.#{extension}" }

    it "returns a new image id" do
      expect(subject.image_id).to_not eq base_image.id
    end
  end

  shared_examples_for "#process when uploading a duplicate image" do
    let(:filename) { "ocp_logo_dupe.#{extension}" }

    it "returns the base_image image id" do
      expect(subject.image_id).to eq base_image.id
    end
  end

  describe "#process" do
    let!(:base_image) do
      create(:image,
             :extension => extension,
             :content   => Base64.encode64(File.read(Rails.root.join("spec", "support", "images", "ocp_logo.#{extension}"))))
    end

    let(:new_image) do
      Image.new(
        :extension => extension,
        :content   => Base64.encode64(File.read(Rails.root.join("spec", "support", "images", filename)))
      )
    end

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
