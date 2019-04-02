describe OrderItem do
  let(:tenant) { create(:tenant, :external_tenant => default_user_hash['identity']['account_number']) }
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
end
