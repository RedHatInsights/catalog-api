describe Catalog::SoftDeleteRestore do
  let(:tenant) { create(:tenant) }
  let(:portfolio) { create(:portfolio, :tenant_id => tenant.id) }
  let(:portfolio_item) { create(:portfolio_item, :portfolio => portfolio, :tenant_id => tenant.id, :discarded_at => Time.current) }

  describe "#process" do
    context "when restoring a soft-deleted record" do
      let!(:svc) { described_class.new(portfolio_item, Digest::SHA1.hexdigest(portfolio_item.discarded_at.to_s)).process }

      it "restores the record" do
        expect(portfolio_item.discarded?).to be_falsey
      end
    end

    context "when attempting to restore a record with the wrong SHA hash" do
      it "raises a NotAuthorized exception" do
        expect { described_class.new(portfolio_item, "MrMaliciousHash").process }.to raise_exception(Catalog::NotAuthorized)
      end
    end
  end
end
