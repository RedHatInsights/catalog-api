describe Catalog::NameAdjust do
  describe "#create_copy_name" do
    let(:item_name) { "MyItem" }
    let(:create_copy_name) { described_class.create_copy_name(item_name, names) }

    context "when passing in multiple Copy Names" do
      let(:names) { [item_name.to_s, "Copy of #{item_name}", "Copy (1) of #{item_name}"] }

      it "returns the highest index in the array" do
        expect(create_copy_name).to eq "Copy (2) of #{item_name}"
      end
    end

    context "when there are not any other copies" do
      let(:names) { [item_name.to_s, "anotheritem"] }

      it "returns the right copy of string" do
        expect(create_copy_name).to eq "Copy of #{item_name}"
      end
    end
  end
end
