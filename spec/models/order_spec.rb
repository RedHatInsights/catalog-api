describe Order do
  let!(:order1) { create(:order) }
  let!(:order2) { create(:order) }
  let!(:order3) { create(:order, :owner => 'barney') }

  context "scoped by owner" do
    it "#by_owner" do
      ManageIQ::API::Common::Request.with_request(default_request) do
        expect(Order.by_owner.collect(&:id)).to match_array([order1.id, order2.id])
        expect(Order.all.count).to eq(3)
      end
    end
  end

  describe "#discard before hook" do
    context "when the order has order items" do
      let!(:order_item) { create(:order_item, :order_id => order1.id) }

      it "destroys order_items associated with the order" do
        order1.order_items << order_item
        order1.discard
        expect(Order.find_by(:id => order1.id)).to be_nil
        expect(OrderItem.find_by(:id => order_item.id)).to be_nil
      end
    end
  end

  describe "#undiscard before hook" do
    context "when the order has order items" do
      let!(:order_item) { create(:order_item, :order_id => order1.id) }

      before do
        order1.order_items << order_item
        order1.save
        order1.discard
      end

      it "restores the order items associated with the order" do
        expect(Order.find_by(:id => order1.id)).to be_nil
        expect(OrderItem.find_by(:id => order_item.id)).to be_nil
        order1 = Order.with_discarded.discarded.first
        order1.undiscard
        expect(Order.find_by(:id => order1.id)).to_not be_nil
        expect(OrderItem.find_by(:id => order_item.id)).to_not be_nil
      end
    end
  end
end
