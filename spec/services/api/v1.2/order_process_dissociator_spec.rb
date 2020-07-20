describe Api::V1x2::Catalog::OrderProcessDissociator do
  describe "#process" do
    let(:order_process) do
      create(:order_process,
             :before_portfolio_item => before_portfolio_item,
             :after_portfolio_item  => after_portfolio_item)
    end
    let(:before_portfolio_item) { create(:portfolio_item) }
    let(:after_portfolio_item) { create(:portfolio_item) }

    subject { described_class.new(order_process, associations_to_remove).process }

    context "when removing a 'before' association" do
      let(:associations_to_remove) { ["before"] }

      it "removes the 'before' association but leaves the 'after'" do
        subject
        order_process.reload
        expect(order_process.before_portfolio_item).to eq(nil)
        expect(order_process.after_portfolio_item).to eq(after_portfolio_item)
      end
    end

    context "when removing an 'after' association" do
      let(:associations_to_remove) { ["after"] }

      it "removes the 'after' association but leaves the 'before'" do
        subject
        order_process.reload
        expect(order_process.after_portfolio_item).to eq(nil)
        expect(order_process.before_portfolio_item).to eq(before_portfolio_item)
      end
    end

    context "when removing both associations" do
      let(:associations_to_remove) { %w[before after] }

      it "removes both associations" do
        subject
        order_process.reload
        expect(order_process.before_portfolio_item).to eq(nil)
        expect(order_process.after_portfolio_item).to eq(nil)
      end
    end
  end
end
