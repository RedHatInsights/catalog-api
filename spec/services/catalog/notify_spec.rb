describe Catalog::Notify do
  let(:subject) { described_class.new(klass, id, payload) }

  describe "#process" do
    context "when the class is not an acceptable notification class" do
      context "when the class is an order item" do
        let(:klass) { "order_item" }
        let(:order) { create(:order) }
        let(:portfolio_item) { create(:portfolio_item) }
        let(:order_item) { create(:order_item, :order_id => order.id, :portfolio_item_id => portfolio_item.id) }
        let(:id) { order_item.id }
        let(:payload) { {"decision" => "yes", "message" => message} }
        let(:order_state_transition) { instance_double("Catalog::OrderStateTransition") }

        before do
          allow(Catalog::OrderStateTransition).to receive(:new).with(order.id).and_return(order_state_transition)
          allow(order_state_transition).to receive(:process)
          @return_value = subject.process
          order_item.reload
        end

        context "when the message is request_finished" do
          let(:message) { "request_finished" }

          it "updates the state" do
            expect(order_item.state).to eq("yes")
          end

          it "delegates to the order state transition" do
            expect(order_state_transition).to have_received(:process)
          end

          it "returns the notify object" do
            expect(@return_value.class).to eq(Catalog::Notify)
            expect(@return_value.notification_object).to eq(order_item)
          end
        end

        context "when the message is anything else" do
          let(:message) { "not_request_finished" }

          it "does not update the state" do
            expect(order_item.state).to eq("Created")
          end

          it "does not call the order state transition" do
            expect(order_state_transition).to_not have_received(:process)
          end

          it "returns the notify object" do
            expect(@return_value.class).to eq(Catalog::Notify)
            expect(@return_value.notification_object).to eq(order_item)
          end
        end
      end

      context "when the class is an approval request" do
        let(:klass) { "approval_request" }
        let(:order) { create(:order) }
        let(:portfolio_item) { create(:portfolio_item) }
        let(:order_item) { create(:order_item, :order_id => order.id, :portfolio_item_id => portfolio_item.id) }
        let(:approval_request) { create(:approval_request, :order_item_id => order_item.id) }
        let(:id) { approval_request.id }
        let(:payload) { {"decision" => "approved", "reason" => "because", "message" => message} }
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
            expect(@return_value.class).to eq(Catalog::Notify)
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
            expect(@return_value.class).to eq(Catalog::Notify)
            expect(@return_value.notification_object).to eq(approval_request)
          end
        end
      end
    end

    context "when the class is not an acceptable notification class" do
      let(:klass) { "nope" }
      let(:id) { "123" }
      let(:payload) { "" }

      it "raises an error" do
        expect { subject.process }.to raise_error(Catalog::InvalidNotificationClass)
      end
    end
  end
end
