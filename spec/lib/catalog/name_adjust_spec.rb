describe Catalog::NameAdjust do
  describe "#create_copy_name" do
    let(:item_name) { "MyItem" }
    let(:max_length) { 20 }
    let(:create_copy_name) { described_class.create_copy_name(item_name, names) }

    context "when passing in multiple Copy Names" do
      let(:names) { [item_name.to_s, "Copy of #{item_name}", "Copy (1) of #{item_name}"] }

      context "when a max_length is provided" do
        let(:item_name) { "SomeLongItemName" }
        let(:create_copy_name) { described_class.create_copy_name(item_name, names, max_length) }

        it "returns the highest index in the array truncated to the max_length" do
          expect(create_copy_name).to eq("Copy (2) of SomeL...")
        end
      end

      context "when a max_length is not provided" do
        let(:names) { [item_name.to_s, "Copy of #{item_name}", "Copy (1) of #{item_name}"] }

        it "returns the highest index in the array" do
          expect(create_copy_name).to eq("Copy (2) of #{item_name}")
        end
      end
    end

    context "when there are not any other copies" do
      let(:names) { [item_name.to_s, "anotheritem"] }

      context "when a max_length is provided" do
        let(:item_name) { "SomeLongItemName" }
        let(:create_copy_name) { described_class.create_copy_name(item_name, names, max_length) }

        it "returns the right copy of string truncated to the max_length" do
          expect(create_copy_name).to eq("Copy of SomeLongI...")
        end
      end

      context "when a max_length is not provided" do

        it "returns the right copy of string" do
          expect(create_copy_name).to eq("Copy of #{item_name}")
        end
      end
    end
  end
end
