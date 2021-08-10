describe Api::V1x0::Catalog::SoftDelete, :type => :service do
  let(:portfolio) { create(:portfolio) }
  let(:portfolio_item) { create(:portfolio_item, :portfolio => portfolio) }

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

    context "when soft-deleting raises an error" do
      let(:subject) { described_class.new(portfolio_item) }

      before do
        allow(portfolio_item).to receive(:discard!).and_raise(Discard::DiscardError)
        allow(portfolio_item).to receive(:discard!) do
          portfolio_item.errors.add(:base, "error 1")
          portfolio_item.errors.add(:base, "error 2")
          raise Discard::DiscardError
        end
      end

      it "raise the error" do
        expect { subject.process }.to raise_exception(Discard::DiscardError, "PortfolioItem #{portfolio_item.id} cannot be deleted: error 1; error 2")
      end
    end

    context "when soft-deleting raises an error in a child object" do
      let(:subject) { described_class.new(portfolio) }
      let(:portfolio_item2) { create(:portfolio_item, :portfolio => portfolio) }

      before do
        create(:order_process, :before_portfolio_item => portfolio_item, :after_portfolio_item => portfolio_item2)
      end

      it "raises an error with a bubbled up message" do
        expect { subject.process }.to raise_exception(
          Discard::DiscardError,
          /#{portfolio_item.id}.*cannot be deleted.*#{portfolio_item2.id}.*cannot be deleted/
        )
      end
    end
  end
end
