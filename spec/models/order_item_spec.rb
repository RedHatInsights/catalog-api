describe OrderItem do
  let(:tenant) { create(:tenant) }
  let(:order) { create(:order, :tenant_id => tenant.id) }
  let(:order_item) { create(:order_item, :order_id => order.id, :portfolio_item_id => 123, :tenant_id => tenant.id) }

  context "updating order item progress messages" do
    it "syncs the time between order_item and progress message" do
      order_item.update_message("test_level", "test message")
      order_item.reload
      last_message = order_item.progress_messages.last
      expect(order_item.updated_at).to be_a(Time)
      expect(last_message.order_item_id.to_i).to eq order_item.id
      expect(last_message.tenant_id).to eq(tenant.id)
    end
  end

  describe "#discard before hook" do
    context "when the order item has progress messages" do
      let(:progress_message) { create(:progress_message, :order_item_id => order_item.id) }

      it "destroys progress_messages associated with the order" do
        order_item.progress_messages << progress_message
        order_item.discard
        expect(OrderItem.find_by(:id => order_item.id)).to be_nil
        expect(ProgressMessage.find_by(:id => progress_message.id)).to be_nil
      end
    end
  end

  describe "#undiscard before hook" do
    context "when the order item has progress messages" do
      let(:progress_message) { create(:progress_message, :order_item_id => order_item.id) }

      before do
        order_item.progress_messages << progress_message
        order_item.save
        order_item.discard
      end

      it "restores the order items associated with the order" do
        expect(OrderItem.find_by(:id => order_item.id)).to be_nil
        expect(ProgressMessage.find_by(:id => progress_message.id)).to be_nil
        order_item = OrderItem.with_discarded.discarded.first
        order_item.undiscard
        expect(OrderItem.find_by(:id => order_item.id)).to_not be_nil
        expect(ProgressMessage.find_by(:id => progress_message.id)).to_not be_nil
      end
    end
  end
end
