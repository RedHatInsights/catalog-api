describe Tenant, :type => :model do
  let(:tenant) do
    create(:tenant,
           :settings => {
             :icon             => "<svg rel='stylesheet'>image</svg>",
             :default_workflow => "1"
           })
  end
  let(:retreived_tenant) { Tenant.find(tenant.id) }

  describe "#setup_settings" do
    context "when retreiving from the db" do
      it "populates the keys as methods" do
        expect(retreived_tenant.icon).to eq tenant.settings["icon"]
        expect(retreived_tenant.default_workflow).to eq tenant.settings["default_workflow"]
      end
    end

    context "when manually adding a new setting and retreiving the key" do
      before do
        tenant.update!(:settings => tenant.settings.merge!(:a_setting => "nerp"))
      end

      it "has the new setting on the hash" do
        expect(retreived_tenant.a_setting).to eq "nerp"
      end
    end
  end

  describe "#add_settings" do
    before { tenant.add_setting(:telephone, "555-867-5309") }

    it "adds the specified setting" do
      expect(retreived_tenant.telephone).to eq "555-867-5309"
    end
  end

  describe "#update_setting" do
    before { tenant.update_setting(:default_workflow, "2") }

    it "updates the setting" do
      expect(retreived_tenant.default_workflow).to eq "2"
    end
  end

  describe "#delete_setting" do
    before { tenant.delete_setting(:icon) }

    it "deletes the setting" do
      expect { retreived_tenant.icon }.to raise_exception(NoMethodError)
    end
  end
end
