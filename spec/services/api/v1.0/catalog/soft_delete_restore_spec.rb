describe Api::V1x0::Catalog::SoftDeleteRestore, :type => :service do
  let(:portfolio_item) { create(:portfolio_item, :discarded_at => Time.current) }

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
