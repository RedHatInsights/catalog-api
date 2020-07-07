describe Api::V1x2::Catalog::OrderProcessAssociator do
  describe "#process" do
    subject { described_class.new(order_process, portfolio_item.id, association) }

    let(:order_process) { create(:order_process) }
    let(:portfolio_item) { create(:portfolio_item) }

    context "when the portfolio item cannot be found" do
      subject { described_class.new(order_process, portfolio_item.id + 1, association) }
      let(:association) { :before_portfolio_item }

      it "raises an error" do
        expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when the association is :before_portfolio_item" do
      let(:association) { :before_portfolio_item }

      it "updates the order process 'before_portfolio_item' step" do
        updated_process = subject.process.order_process
        expect(updated_process.before_portfolio_item).to eq(portfolio_item)
      end
    end

    context "when the association is :after_portfolio_item" do
      let(:association) { :after_portfolio_item }

      it "updates the order process 'after_portfolio_item' step" do
        updated_process = subject.process.order_process
        expect(updated_process.after_portfolio_item).to eq(portfolio_item)
      end
    end
  end
end
