describe Api::V1x2::Catalog::OrderProcessAssociator do
  describe "#process" do
    subject { described_class.new(order_process, portfolio_item.id, association) }

    let(:order_process) { create(:order_process) }
    let(:portfolio_item) { create(:portfolio_item) }

    context "when the portfolio item cannot be found" do
      subject { described_class.new(order_process, portfolio_item.id + 1, association) }
      let(:association) { :pre }

      it "raises an error" do
        expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when the association is :pre" do
      let(:association) { :pre }

      it "updates the order process 'pre' step" do
        updated_process = subject.process.order_process
        expect(updated_process.pre).to eq(portfolio_item)
      end
    end
  end
end
