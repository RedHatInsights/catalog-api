describe Order do
  let(:tenant) { create(:tenant) }
  let!(:order1) { create(:order, :tenant_id => tenant.id) }
  let!(:order2) { create(:order, :tenant_id => tenant.id) }
  let!(:order3) { create(:order, :tenant_id => tenant.id, :owner => 'barney') }

  let!(:order_item) { create(:order_item, :order_id => order1.id, :portfolio_item_id => "1", :tenant_id => tenant.id) }
  let!(:order_item2) { create(:order_item, :order_id => order1.id, :portfolio_item_id => "1", :tenant_id => tenant.id) }

  context "scoped by owner" do
    it "#by_owner" do
      ManageIQ::API::Common::Request.with_request(default_request) do
        expect(Order.by_owner.collect(&:id)).to match_array([order1.id, order2.id])
        expect(Order.all.count).to eq(3)
      end
    end
  end

  describe "#transition_state" do
    before do
      order_item.update(:state => expected_state)
    end

    let(:transition) do
      order1.transition_state
      order1.reload
    end

    context "when the order item's state hasn't been updated" do
      let(:expected_state) { "Ordered" }

      it "sets the state to Ordered" do
        transition
        expect(order1.state).to eq 'Ordered'
      end
    end

    context "when the order item gets updated to denied" do
      let(:expected_state) { "Denied" }

      it "sets the state to Denied" do
        transition
        expect(order1.state).to eq 'Denied'
      end

      it "sets the state to Denied even if only one is denied" do
        order_item2.update(:state => "Approved")
        transition
        expect(order1.state).to eq 'Denied'
      end
    end

    context "when the order item gets updated to failed" do
      let(:expected_state) { "Failed" }

      it "sets the state to Failed" do
        transition
        expect(order1.state).to eq 'Failed'
      end
    end

    context "when the order item gets updated to approved" do
      let(:expected_state) { "Approved" }

      it "does not transition to approved until all items are approved" do
        transition
        expect(order1.state).to eq 'Ordered'
      end

      it "sets the state to Approved" do
        order_item2.update(:state => "Approved")
        transition
        expect(order1.state).to eq 'Approved'
      end
    end

    context "when the order item gets updated to completed" do
      let(:expected_state) { "Completed" }

      it "does not transition to completed until all items are completed" do
        transition
        expect(order1.state).to eq 'Ordered'
      end

      it "sets the state to Completed" do
        order_item2.update(:state => "Completed")
        transition
        expect(order1.state).to eq 'Completed'
      end
    end
  end
end
