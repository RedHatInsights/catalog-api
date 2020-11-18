describe Catalog::ApprovalTransition do
  let(:so) { class_double(Catalog::SubmitNextOrderItem).as_stubbed_const(:transfer_nested_constants => true) }
  let(:submit_order) { instance_double(Catalog::SubmitNextOrderItem) }
  let(:topo_ex) { ::Catalog::TopologyError.new("boom") }

  let(:req) { { :headers => default_headers, :original_url => "localhost/nope" } }

  let(:order) { create(:order) }

  let!(:order_item) do
    Insights::API::Common::Request.with_request(req) do
      create(:order_item, :order => order)
    end
  end

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
    end

    context "when denied" do
      before do
        approval.update(:state => "denied")
      end

      it "returns the state as denied" do
        expect(order_item_transition.process.state).to eq "Denied"
      end

      it "does not call out to submit order" do
        expect(submit_order).to receive(:process).exactly(0).times
        order_item_transition.process
      end

      it "marks the order item as denied" do
        order_item_transition.process
        order_item.reload
        expect(order_item.state).to eq "Denied"
      end

      it "marks the order as failed" do
        order_item_transition.process
        order.reload
        expect(order.state).to eq "Failed"
      end

      it "finalizes the Order" do
        order_item_transition.process
        order.reload
        expect(order.state).to eq("Failed")
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

    context "when the call to submit order fails" do
      before do
        approval.update(:state => "approved")
        allow(submit_order).to receive(:process).and_raise(topo_ex)
      end

      it "blows up" do
        order_item_transition.process
        msg = order.progress_messages.last
        expect(msg.level).to eq "error"
        expect(msg.message).to eq "Error when submitting order item #{order_item.id}: #{topo_ex.message}"
      end
    end

    context "when the approval fails" do
      before do
        approval.update(:state => "error", :reason => 'Error Sending Email')
      end

      it "fails the order" do
        order_item_transition.process
        msg = order.progress_messages.last
        expect(msg.level).to eq "error"
        expect(msg.message).to match(/Error Sending Email/)
      end
    end
  end
end
