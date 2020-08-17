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

    context "when there are existing tags" do
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

        allow(Api::V1x2::Catalog::AddToOrderViaOrderProcess).to receive(:new)
          .with(before_params)
          .and_return(add_to_order_via_order_process)
        allow(Api::V1x2::Catalog::AddToOrderViaOrderProcess).to receive(:new)
          .with(after_params)
          .and_return(add_to_order_via_order_process)

        allow(add_to_order_via_order_process).to receive(:process)
      end

      context "when there is 1 existing tag on the portfolio" do
        before do
          portfolio.tag_add("order_processes", :namespace => "catalog", :value => order_process.id)
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

      context "when there is 1 existing tag on the portfolio_item" do
        before do
          portfolio_item.tag_add("order_processes", :namespace => "catalog", :value => order_process.id)
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

      context "when both the portfolio_item and portfolio have tags" do
        context "when the tags are the same" do
          before do
            portfolio_item.tag_add("order_processes", :namespace => "catalog", :value => order_process.id)
            portfolio.tag_add("order_processes", :namespace => "catalog", :value => order_process.id)
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

        context "when the tags are different" do
          let(:before_params) do
            {
              :order_id          => order.id,
              :portfolio_item_id => before_portfolio_item.id,
              :process_sequence  => 1,
              :process_scope     => "before"
            }
          end
          let(:before_params2) do
            {
              :order_id          => order.id,
              :portfolio_item_id => before_portfolio_item2.id,
              :process_sequence  => 2,
              :process_scope     => "before"
            }
          end

          let(:after_params) do
            {
              :order_id          => order.id,
              :portfolio_item_id => after_portfolio_item.id,
              :process_sequence  => 5,
              :process_scope     => "after"
            }
          end
          let(:after_params2) do
            {
              :order_id          => order.id,
              :portfolio_item_id => after_portfolio_item2.id,
              :process_sequence  => 4,
              :process_scope     => "after"
            }
          end

          let(:before_portfolio_item2) { create(:portfolio_item) }
          let(:after_portfolio_item2) { create(:portfolio_item) }
          let(:order_process2) do
            create(:order_process,
                   :before_portfolio_item => before_portfolio_item2,
                   :after_portfolio_item  => after_portfolio_item2)
          end

          before do
            TagLink.create(:order_process_id => order_process2.id, :tag_name => "/catalog/other=#{order_process2.id}")

            portfolio_item.tag_add("order_processes", :namespace => "catalog", :value => order_process.id)
            portfolio.tag_add("other", :namespace => "catalog", :value => order_process2.id)
            allow(Api::V1x2::Catalog::AddToOrderViaOrderProcess).to receive(:new)
              .with(before_params2)
              .and_return(add_to_order_via_order_process)
            allow(Api::V1x2::Catalog::AddToOrderViaOrderProcess).to receive(:new)
              .with(after_params2)
              .and_return(add_to_order_via_order_process)
          end

          it "applies the process sequence of '3' to the order item" do
            subject
            expect(order.order_items.first.process_sequence).to eq(3)
          end

          it "applies the process scope of 'applicable' to the order item" do
            subject
            expect(order.order_items.first.process_scope).to eq("applicable")
          end

          it "delegates creation of two 'before' order_items with the appropriate process sequences" do
            expect(Api::V1x2::Catalog::AddToOrderViaOrderProcess).to receive(:new).with(before_params)
            expect(Api::V1x2::Catalog::AddToOrderViaOrderProcess).to receive(:new).with(before_params2)

            subject
          end

          it "delegates creation of two 'after' order_items with the appropriate process sequences" do
            expect(Api::V1x2::Catalog::AddToOrderViaOrderProcess).to receive(:new).with(after_params)
            expect(Api::V1x2::Catalog::AddToOrderViaOrderProcess).to receive(:new).with(after_params2)

            subject
          end
        end
      end
    end
  end
end
