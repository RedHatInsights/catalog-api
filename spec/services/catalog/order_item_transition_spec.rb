describe Catalog::OrderItemTransition do
  let(:so) { class_double(Catalog::SubmitOrder).as_stubbed_const(:transfer_nested_constants => true) }
  let(:submit_order) { instance_double(Catalog::SubmitOrder) }

  let(:order) { create(:order) }
  let(:order_item) do
    create(:order_item,
           :order_id          => order.id,
           :portfolio_item_id => "1",
           :context           => {
             :headers => encoded_user_hash, :original_url => "localhost/nope"
           })
  end

  let(:approval) do
    create(:approval_request,
           :workflow_ref  => "1",
           :order_item_id => order_item.id)
  end

  let(:order_item_transition) { described_class.new(order_item.id) }

  before do
    allow(so).to receive(:new).and_return(submit_order)
    allow(submit_order).to receive(:process).and_return(submit_order)
  end

  describe "#process" do
    context "when approved" do
      before do
        approval.update(:state => "approved")
      end

      it "returns the state as approved" do
        expect(order_item_transition.process.state).to eq "approved"
      end

      it "calls out to Catalog::SubmitOrder" do
        expect(so).to receive(:new).with(order.id)
        expect(submit_order).to receive(:process).once
        order_item_transition.process
      end
    end

    context "when denied" do
      before do
        approval.update(:state => "denied")
      end

      it "returns the state as denied" do
        expect(order_item_transition.process.state).to eq "denied"
      end

      it "does not call out to submit order" do
        expect(submit_order).to receive(:process).exactly(0).times
        order_item_transition.process
      end

      it "marks the order item as denied" do
        order_item_transition.process
        order_item.reload
        expect(order_item.state).to eq "Denied"
      end

      it "marks the order as denied" do
        order_item_transition.process
        order.reload
        expect(order.state).to eq "Denied"
      end
    end

    context "when pending" do
      it "returns the state as pending" do
        expect(order_item_transition.process.state).to eq "pending"
      end
    end
  end
end
