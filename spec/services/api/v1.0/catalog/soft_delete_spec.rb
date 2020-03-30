describe Catalog::SoftDelete, :type => :service do
  let(:portfolio_item) { create(:portfolio_item) }

  describe "#process" do
    context "when soft-deleting a record" do
      let!(:subject) { described_class.new(portfolio_item).process }

      it "discards the record" do
        expect(portfolio_item.discarded?).to be_truthy
      end

      it "sets the restore_key to the hash of the discarded_at column" do
        expect(subject.restore_key).to eq Digest::SHA1.hexdigest(portfolio_item.discarded_at.to_s)
      end
    end
  end
end
