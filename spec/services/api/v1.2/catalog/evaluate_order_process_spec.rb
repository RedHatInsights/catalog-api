describe Api::V1x2::Catalog::EvaluateOrderProcess, :type => :service do
  describe "#process" do
    let(:order) { create(:order) }
    let!(:order_item) { create(:order_item, :order => order, :portfolio_item => portfolio_item) }
    let(:portfolio_item) { create(:portfolio_item, :portfolio => portfolio) }
    let(:portfolio) { create(:portfolio) }

    subject { described_class.new(order).process }

    context "when there are no existing tags on the portfolio or portfolio_item" do
      it "applies the process sequence of '1' to the order item" do
        subject
        expect(order.order_items.first.process_sequence).to eq(1)
      end

      it "applies the proccess scope of 'applicable' to the order item" do
        subject
        expect(order.order_items.first.process_scope).to eq("applicable")
      end

      it "does not add any other order items to the order" do
        subject
        expect(order.order_items.count).to eq(1)
      end
    end

    context "when there is 1 existing tag on the portfolio_item" do
      let(:before_params) do
        {
          :order_id          => order.id,
          :portfolio_item_id => before_portfolio_item.id,
          :process_sequence  => 1,
          :process_scope     => "before"
        }
      end

      let(:after_params) do
        {
          :order_id          => order.id,
          :portfolio_item_id => after_portfolio_item.id,
          :process_sequence  => 3,
          :process_scope     => "after"
        }
      end
      let(:before_portfolio_item) { create(:portfolio_item) }
      let(:after_portfolio_item) { create(:portfolio_item) }
      let(:order_process) do
        create(:order_process,
               :before_portfolio_item => before_portfolio_item,
               :after_portfolio_item  => after_portfolio_item)
      end
      let(:add_to_order_via_order_process) { instance_double(Api::V1x2::Catalog::AddToOrderViaOrderProcess) }

      before do
        TagLink.create(:order_process_id => order_process.id, :tag_name => "/catalog/order_processes=#{order_process.id}")
        portfolio.tag_add("order_processes", :namespace => "catalog", :value => order_process.id)

        allow(Api::V1x2::Catalog::AddToOrderViaOrderProcess).to receive(:new)
          .with(before_params)
          .and_return(add_to_order_via_order_process)
        allow(Api::V1x2::Catalog::AddToOrderViaOrderProcess).to receive(:new)
          .with(after_params)
          .and_return(add_to_order_via_order_process)

        allow(add_to_order_via_order_process).to receive(:process)
      end

      it "applies the process sequence of '2' to the order item" do
        subject
        expect(order.order_items.first.process_sequence).to eq(2)
      end

      it "applies the process scope of 'applicable' to the order item" do
        subject
        expect(order.order_items.first.process_scope).to eq("applicable")
      end

      it "delegates creation of a 'before' order_item with a process sequence of 1" do
        expect(Api::V1x2::Catalog::AddToOrderViaOrderProcess).to receive(:new).with(before_params)

        subject
      end

      it "delegates creation of an 'after' order_item with a process sequence of 3" do
        expect(Api::V1x2::Catalog::AddToOrderViaOrderProcess).to receive(:new).with(after_params)

        subject
      end
    end
  end
end
