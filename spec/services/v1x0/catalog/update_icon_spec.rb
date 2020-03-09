describe V1x0::Catalog::UpdateIcon, :type => :service do
  let(:subject) { described_class.new(icon.id, params) }
  let(:portfolio_item) { create(:portfolio_item) }

  describe "#process" do
    let(:image) { create(:image, :content => Base64.strict_encode64(File.read(Rails.root.join("spec", "support", "images", "ocp_logo.svg")))) }
    let(:icon) { create(:icon, :source_ref => "127", :image => image, :restore_to => portfolio_item) }

    context "when updating an icon" do
      let(:params) do
        {
          :source_id  => "4",
          :source_ref => "128",
          :content    => form_upload_test_image("miq_logo.jpg")
        }
      end

      it "updates the image" do
        new_image = subject.process.icon.image

        expect(new_image.id).to_not eq image.id
        expect(new_image.extension).to_not eq image.extension
      end

      it "updates the other fields" do
        icon = subject.process.icon

        expect(icon.source_ref).to eq params[:source_ref]
        expect(icon.source_id).to eq params[:source_id]
      end

      it "deletes the old image" do
        expect { Icon.find(image.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
