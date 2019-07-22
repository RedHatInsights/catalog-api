describe Catalog::NotifyApprovalRequest do
  let(:subject) { described_class.new(ref_id, payload['payload'], payload['message']) }

  describe "#process" do
    context "when the class is an approval request" do
      let(:order) { create(:order) }
      let(:portfolio_item) { create(:portfolio_item) }
      let(:order_item) { create(:order_item, :order_id => order.id, :portfolio_item_id => portfolio_item.id) }
      let!(:approval_request) { create(:approval_request, :order_item_id => order_item.id, :approval_request_ref => "123") }
      let(:ref_id) { "123" }
      let(:payload) { { "payload" => {"decision" => "approved", "reason" => "because" }, "message" => message } }
      let(:approval_transition) { instance_double("Catalog::ApprovalTransition") }

      before do
        allow(Catalog::ApprovalTransition).to receive(:new).with(order_item.id).and_return(approval_transition)
        allow(approval_transition).to receive(:process)
        @return_value = subject.process
        approval_request.reload
      end

      context "when the message is request_finished" do
        let(:message) { "request_finished" }

        it "updates the state" do
          expect(approval_request.state).to eq("approved")
        end

        it "updates the reason" do
          expect(approval_request.reason).to eq("because")
        end

        it "delegates to the approval transition" do
          expect(approval_transition).to have_received(:process)
        end

        it "returns the notify object" do
          expect(@return_value.class).to eq(Catalog::NotifyApprovalRequest)
          expect(@return_value.notification_object).to eq(approval_request)
        end
      end

      context "when the message is anything else" do
        let(:message) { "not_request_finished" }

        it "does not update the state" do
          expect(approval_request.state).to eq("undecided")
        end

        it "does not update the reason" do
          expect(approval_request.reason).to eq(nil)
        end

        it "does not call the approval transition" do
          expect(approval_transition).to_not have_received(:process)
        end

        it "returns the notify object" do
          expect(@return_value.class).to eq(Catalog::NotifyApprovalRequest)
          expect(@return_value.notification_object).to eq(approval_request)
        end
      end
    end
  end
end
