describe PortfolioItem do
  let(:item) { PortfolioItem.new }
  let(:service_offering_ref) { "1" }
  let(:owner) { 'wilma' }

  context "requires a service_offering_ref" do
    before do
      item.owner = owner
    end

    it "is not valid without a service_offering_ref" do
      expect(item).to_not be_valid
    end

    it "is valid when we set a service_offering_ref" do
      item.service_offering_ref = service_offering_ref
      expect(item).to be_valid
    end
  end

  context "requires an owner" do
    before do
      item.service_offering_ref = service_offering_ref
    end

    it "is not valid without an owner" do
      expect(item).to_not be_valid
    end

    it "is valid when we set an owner" do
      item.owner = owner
      expect(item).to be_valid
    end
  end
end
