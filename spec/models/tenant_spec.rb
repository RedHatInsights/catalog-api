describe Tenant do
  describe "#{described_class}.tenancy_enabled?" do
    it "is enabled by default" do
      expect(Tenant.tenancy_enabled?).to be_truthy
    end

    it "is disabled when ENV['BYPASS_TENANCY'] is set" do
      disable_tenancy

      expect(ENV['BYPASS_TENANCY']).to be_truthy
      expect(Tenant.tenancy_enabled?).to be_falsey
    end
  end
end
