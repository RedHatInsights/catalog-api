describe PortfolioItem do
  let(:item) { PortfolioItem.new }
  let(:service_offering_ref) { "1" }

  describe "requires a service_offering_ref" do
    it "is not valid without a service_offering_ref" do
      expect(item).to_not be_valid
    end

    it "is valid when we set a service_offering_ref" do
      item.service_offering_ref = service_offering_ref
      expect(item).to be_valid
    end
  end
end
