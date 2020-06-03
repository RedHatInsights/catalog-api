describe PortfolioItem do
  let(:item) { build(:portfolio_item) }

  let(:service_offering_ref) { "1" }
  let(:owner) { 'wilma' }

  context "requires a service_offering_ref" do
    before do
      item.owner = owner
    end

    it "is not valid without a service_offering_ref" do
      item.service_offering_ref = nil
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
      item.owner = nil
      expect(item).to_not be_valid
    end

    it "is valid when we set an owner" do
      item.owner = owner
      expect(item).to be_valid
    end
  end

  context "default socpe" do
    it "returns portfolio_items sorted by case insensitive names" do
      %w[ab bb Bc Ad].each { |name| create(:portfolio_item, :name => name) }

      expect(PortfolioItem.pluck(:name)).to eq(%w[ab Ad bb Bc])
    end
  end

  context ".policy_class" do
    it "is PortfolioItemPolicy" do
      expect(PortfolioItem.policy_class).to eq(PortfolioItemPolicy)
    end
  end

  context "length restrictions" do
    it "raises validation error" do
      expect do
        PortfolioItem.create!(:name => 'a'*513, :description => 'abc', :owner => 'fred')
      end.to raise_error(ActiveRecord::RecordInvalid, /Name is too long/)
    end
  end
end
