describe Catalog::OrderStateTransition do
  let(:order) { create(:order) }

  let(:order_item) { create(:order_item, :order => order) }
  let(:order_item2) { create(:order_item, :order => order) }

  describe "#process" do
    before do
      order.update(:state => "Ordered")
      order_item.update(:state => expected_state)
    end

    let(:transition) do
      described_class.new(order).process
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

      it "sets the state to Failed if this is the only order item" do
        transition
        expect(order.state).to eq 'Failed'
      end

      it "sets the state to Failed even if others are completed" do
        order_item2.update(:state => "Completed")
        transition
        expect(order.state).to eq 'Failed'
      end
    end

    context "when the order item gets updated to failed" do
      let(:expected_state) { "Failed" }

      it "sets the state to Failed" do
        transition
        expect(order.state).to eq('Failed')
      end

      it "sets the state to Failed even if other items are completed" do
        order_item2.update(:state => "Completed")
        transition
        expect(order.state).to eq('Failed')
      end

      it "changes not the order state even if other items are not completed" do
        order_item2.update(:state => "Ordered")
        transition
        expect(order.state).to eq('Ordered')
      end
    end

    context "when the order item gets updated to completed" do
      let(:expected_state) { "Completed" }

      it "does not transition to completed until all items are completed" do
        order_item2.update(:state => "Created")
        transition
        expect(order.state).to eq('Ordered')
      end

      it "sets the state to Completed if all items are completed" do
        order_item2.update(:state => "Completed")
        transition
        expect(order.state).to eq('Completed')
      end
    end

    context "when the order item gets updated to canceled" do
      let(:expected_state) { "Canceled" }

      it "sets the state to Canceled if all items are finished" do
        order_item2.update(:state => "Completed")
        transition
        expect(order.state).to eq('Canceled')
      end

      it "does not transition the state if other items are not finished" do
        order_item2.update(:state => "Created")
        transition
        expect(order.state).to eq("Ordered")
      end
    end

    context "when order items have sensitive service_parameters" do
      before do
        order_item[:service_parameters_raw] = {'password' => 'abc'}
        order_item.save
        order_item2[:service_parameters_raw] = {'token' => '123'}
        order_item2.update(:state => 'Completed')
      end

      let(:expected_state) { "Completed" }

      it "clears all service_parameters_raw" do
        transition
        order_item.reload
        order_item2.reload
        expect(order_item[:service_parameters_raw]).to be_nil
        expect(order_item2[:service_parameters_raw]).to be_nil
      end
    end
  end
end
