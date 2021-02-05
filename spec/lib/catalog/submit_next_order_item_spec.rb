describe Catalog::SubmitNextOrderItem, :type => [:service, :inventory, :current_forwardable] do
  let(:submit_next_order_item) { described_class.new(params) }
  let(:order) do
    create(:order).tap do |the_order|
      create_list(:order_item, 3, :order => the_order)
      the_order.reload
    end
  end

  context "with multiple order items" do
    let(:params) { order.id.to_s }
    let!(:order_items) { order.order_items }

    before do
      allow(Order).to receive(:find_by!).with(:id => params).and_return(order)
    end

    shared_examples_for "order the desired item" do
      before do
        order_items.each.with_index(1) do |item, index|
          allow(item).to receive(:can_order?).and_return(index >= ordered_item)
        end
      end

      it "orders the desired item" do
        expect(Catalog::SubmitOrderItem).to receive(:new).with(order_items[ordered_item - 1]).and_return(double(:submit_order_item, :process => nil))
        expect(submit_next_order_item.process.order.state).to eq('Ordered')
      end
    end

    context "when no order item is orderable" do
      before do
        order_items.each { |item| allow(item).to receive(:can_order?).and_return(false) }
      end

      it 'does not order any item' do
        expect(Catalog::SubmitOrderItem).not_to receive(:new)
        submit_next_order_item.process
      end
    end

    context "when the first item becomes orderable" do
      let(:ordered_item) { 1 }

      it_behaves_like "order the desired item"
    end

    context "when the first item is not orderable the second one is" do
      let(:ordered_item) { 2 }

      it_behaves_like "order the desired item"
    end

    context "when the first and second items are not orderable but the third one is" do
      let(:ordered_item) { 3 }

      it_behaves_like "order the desired item"
    end
  end

  context "when the order ID is invalid" do
    let(:params) { (order.id + 10).to_s }

    it "raises an exception" do
      expect { submit_next_order_item.process }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
