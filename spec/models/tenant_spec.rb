describe Tenant do
  describe "#{described_class}.tenancy_enabled?" do
    it "is enabled by default" do
      expect(Tenant.tenancy_enabled?).to be_truthy
    end
  end
end
