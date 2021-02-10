describe Catalog::ApprovalTransition do
  let(:so) { class_double(Catalog::SubmitNextOrderItem).as_stubbed_const(:transfer_nested_constants => true) }
  let(:submit_order) { instance_double(Catalog::SubmitNextOrderItem) }
  let(:topo_ex) { ::Catalog::TopologyError.new("boom") }

  let(:req) { { :headers => default_headers, :original_url => "localhost/nope" } }

  let(:order) { create(:order) }

  let(:order_items) do
    Insights::API::Common::Request.with_request(req) do
      create_list(:order_item, 2, :order => order)
    end
  end

  let!(:order_item) { order_items.first }
  let(:after_item) { order_items.second }

  let(:approval) do
    create(:approval_request, :order_item => order_item)
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
        expect(order_item_transition.process.state).to eq("Approved")
      end

      it "calls out to Catalog::SubmitNextOrderItem" do
        expect(so).to receive(:new).with(order.id)
        expect(submit_order).to receive(:process).once do
          order_item.reload
          expect(order_item.state).to eq("Approved")
        end
        order_item_transition.process
      end

      it "finalizes the Order" do
        order_item_transition.process
        order.reload
        expect(order.state).to eq("Ordered")
      end

      it "does not modify the state of other items" do
        order_item_transition.process
        after_item.reload
        expect(after_item.state).to eq("Created")
      end
    end

    context "when denied" do
      before do
        approval.update(:state => "denied")
      end

      it "returns the state as denied" do
        expect(order_item_transition.process.state).to eq("Denied")
      end

      it "does not call out to submit order" do
        expect(submit_order).to receive(:process).exactly(0).times
        order_item_transition.process
      end

      it "marks the order item as denied" do
        order_item_transition.process
        order_item.reload
        expect(order_item.state).to eq("Denied")
        expect(order_item.progress_messages.last.message).to match(/Denied/)
      end

      it "marks the order as failed" do
        order_item_transition.process
        order.reload
        expect(order.state).to eq("Failed")
      end

      it "marks other items as canceled" do
        order_item_transition.process
        after_item.reload
        expect(after_item.state).to eq("Canceled")
        expect(after_item.progress_messages.last.message).to match(/Canceled/)
      end
    end

    context "when canceled" do
      before do
        approval.update(:state => "canceled")
      end

      it "returns the state as canceled" do
        expect(order_item_transition.process.state).to eq "Canceled"
      end

      it "does not call out to submit order" do
        expect(submit_order).to receive(:process).exactly(0).times
        order_item_transition.process
      end

      it "marks the order item as canceled" do
        order_item_transition.process
        order_item.reload
        expect(order_item.state).to eq "Canceled"
      end

      it "marks other items as canceled" do
        order_item_transition.process
        after_item.reload
        expect(after_item.state).to eq "Canceled"
      end

      it "marks the order as canceled" do
        order_item_transition.process
        order.reload
        expect(order.state).to eq "Canceled"
      end
    end

    context "when pending" do
      it "returns the state as pending" do
        expect(order_item_transition.process.state).to eq "Pending"
      end
    end

    context "when the approval fails" do
      before do
        approval.update(:state => "error", :reason => 'Error Sending Email')
      end

      it "marks the order item as failed" do
        order_item_transition.process
        order_item.reload
        expect(order_item.state).to eq "Failed"
      end

      it "marks other items as cancel" do
        order_item_transition.process
        after_item.reload
        expect(after_item.state).to eq "Canceled"
      end

      it "fails the order" do
        order_item_transition.process
        order.reload
        expect(order.state).to eq "Failed"
      end
    end
  end
end
