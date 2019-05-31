describe Catalog::OrderStateTransition do
  let(:tenant) { create(:tenant) }
  let(:order) { create(:order, :tenant_id => tenant.id) }

  let(:order_item) { create(:order_item, :order_id => order.id, :portfolio_item_id => "1", :tenant_id => tenant.id) }
  let(:order_item2) { create(:order_item, :order_id => order.id, :portfolio_item_id => "1", :tenant_id => tenant.id) }

  describe "#process" do
    before do
      order_item.update(:state => expected_state)
    end

    let(:transition) do
      described_class.new(order.id).process
      order.reload
    end

    context "when the order item's state hasn't been updated" do
      let(:expected_state) { "Ordered" }

      it "sets the state to Ordered" do
        transition
        expect(order.state).to eq 'Ordered'
      end
    end

    context "when the order item gets updated to denied" do
      let(:expected_state) { "Denied" }

      it "sets the state to Failed" do
        transition
        expect(order.state).to eq 'Failed'
      end

      it "sets the state to Failed even if only one is denied" do
        order_item2.update(:state => "Approved")
        transition
        expect(order.state).to eq 'Failed'
      end
    end

    context "when the order item gets updated to failed" do
      let(:expected_state) { "Failed" }

      it "sets the state to Failed" do
        transition
        expect(order.state).to eq 'Failed'
      end
    end

    context "when the order item gets updated to completed" do
      let(:expected_state) { "Completed" }

      it "does not transition to completed until all items are completed" do
        order_item2.update(:state => "Created")
        transition
        expect(order.state).to eq 'Ordered'
      end

      it "sets the state to Completed" do
        order_item2.update(:state => "Completed")
        transition
        expect(order.state).to eq 'Completed'
      end
    end

    context "when the order item gets updated to canceled" do
      let(:expected_state) { "Canceled" }

      it "sets the state to Canceled" do
        transition
        expect(order.state).to eq 'Canceled'
      end
    end
  end
end
