describe Catalog::NameAdjust do
  describe "#create_copy_name" do
    let(:item_name) { "MyItem" }
    let(:create_copy_name) { described_class.create_copy_name(item_name, names) }

    context "when passing in multiple Copy Names" do
      let(:names) { [item_name.to_s, "Copy of #{item_name}", "Copy (1) of #{item_name}"] }

      context "when the copied name would be greater than 64 characters" do
        let(:item_name) { "CopiedNamesThatAreGreaterThanSixtyFourCharactersLongWillBeTruncated"}

        it "returns the highest index in the array truncated to 64 characters" do
          expect(create_copy_name).to eq "Copy (2) of #{item_name}".truncate(64)
        end
      end

      context "when the copied name is less than 64 characters" do
        let(:names) { [item_name.to_s, "Copy of #{item_name}", "Copy (1) of #{item_name}"] }

        it "returns the highest index in the array" do
          expect(create_copy_name).to eq "Copy (2) of #{item_name}"
        end
      end
    end

    context "when there are not any other copies" do
      let(:names) { [item_name.to_s, "anotheritem"] }

      context "when the copied name would be greater than 64 characters" do
        let(:item_name) { "CopiedNamesThatAreGreaterThanSixtyFourCharactersLongWillBeTruncated"}

        it "returns the right copy of string truncated to 64 characters" do
          expect(create_copy_name).to eq "Copy of #{item_name}".truncate(64)
        end
      end

      context "when the copied name is less than 64 characters" do

        it "returns the right copy of string" do
          expect(create_copy_name).to eq "Copy of #{item_name}"
        end
      end
    end
  end
end
