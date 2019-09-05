describe Catalog::OverrideIcon do
  let(:tenant) { create(:tenant) }
  let(:portfolio) { create(:portfolio, :tenant_id => tenant.id) }
  let!(:portfolio_item) { create(:portfolio_item, :portfolio => portfolio, :tenant_id => tenant.id) }
  let(:image) { Image.create(:content => Base64.strict_encode64(File.read(Rails.root.join("spec", "support", "images", "ocp_logo.svg"))), :tenant_id => tenant.id) }
  let!(:icon1) { create(:icon, :image => image, :tenant_id => tenant.id, :portfolio_item_id => portfolio_item.id) }
  let!(:icon2) { create(:icon, :image => image, :tenant_id => tenant.id, :portfolio_item_id => portfolio_item.id) }

  describe "#process" do
    context "when overriding an icon" do
      before { described_class.new(icon2.id, portfolio_item.id).process }

      it "destroys the old icon" do
        expect { Icon.find(icon1.id) }.to raise_exception(ActiveRecord::RecordNotFound)
      end

      it "sets the portfolio_item icon to the one specified" do
        expect(portfolio_item.icons.first.id).to eq icon2.id
      end
    end
  end
end
