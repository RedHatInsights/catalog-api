describe ApprovalRequestListener do
  let(:approval_request_ref) { "0" }
  let(:client)               { double(:client) }
  let(:event)                { ApprovalRequestListener::EVENT_REQUEST_FINISHED }
  let(:event_message)        { "request_finished" }
  let(:payload)              { { "request_id" => request_id, "decision" => decision, "reason" => reason } }
  let(:request_id)           { "1" }

  let(:transition_class) { class_double(Catalog::ApprovalTransition).as_stubbed_const(:transfer_nested_constants => true) }
  let(:transition_instance) { instance_double(Catalog::ApprovalTransition) }

  describe "#subscribe_to_approval_updates" do
    let(:message) { ManageIQ::Messaging::ReceivedMessage.new(nil, event, payload, nil, client) }
    let(:order) { create(:order) }
    let!(:order_item) do
      create(:order_item,
             :order_id          => order.id,
             :portfolio_item_id => "234",
             :context           => default_request)
    end
    let!(:approval_request) do
      ApprovalRequest.create!(
        :approval_request_ref => approval_request_ref,
        :workflow_ref         => "2323",
        :order_item_id        => order_item.id
      )
    end

    before do
      allow(ManageIQ::Messaging::Client).to receive(:open).with(
        :protocol   => :Kafka,
        :client_ref => ApprovalRequestListener::CLIENT_AND_GROUP_REF,
        :encoding   => 'json'
      ).and_yield(client)
      allow(client).to receive(:subscribe_topic).with(
        :service     => ApprovalRequestListener::SERVICE_NAME,
        :persist_ref => ApprovalRequestListener::CLIENT_AND_GROUP_REF,
        :max_bytes   => 500_000
      ).and_yield(message)

      allow(transition_class).to receive(:new).and_return(transition_instance)
      allow(transition_instance).to receive(:process).and_return(transition_instance)
    end

    context "when the approval request is not findable" do
      context "when the request_id is anything else" do
        let(:payload) { {"request_id" => "10" } }

        it "creates a progress message about the payload" do
          expect(Rails.logger).to receive(:error).with("Could not find Approval Request with payload of #{payload}")
          subject.subscribe_to_approval_updates
        end

        it "does not update the approval request" do
          subject.subscribe_to_approval_updates
          approval_request.reload
          expect(approval_request.state).to eq("undecided")
        end
      end

      context "and the approval is finished with an approval or denial" do
        let(:reason)   { "System Approved" }
        let(:decision) { "approved" }

        it "creates a progress message about the approval request error" do
          expect(Rails.logger).to receive(:error).with("Could not find Approval Request with payload of #{payload}")
          subject.subscribe_to_approval_updates
        end

        it "does not update the approval request" do
          subject.subscribe_to_approval_updates
          approval_request.reload
          expect(approval_request.state).to eq("undecided")
        end
      end
    end

    context "when the state of the approval is approved" do
      let(:decision)             { "approved" }
      let(:reason)               { "System Approved" }
      let(:approval_request_ref) { "1" }

      it "creates a progress message about the payload" do
        subject.subscribe_to_approval_updates
        latest_progress_message = ProgressMessage.second_to_last
        expect(latest_progress_message.level).to eq("info")
        expect(latest_progress_message.message).to eq("Approval #{approval_request.id} message: #{event_message} decision:  #{decision}")
      end

      it "updates the approval request to be approved" do
        subject.subscribe_to_approval_updates
        approval_request.reload
        expect(approval_request.state).to eq("approved")
      end

      it "calls the transition" do
        expect(transition_instance).to receive(:process).once
        subject.subscribe_to_approval_updates
      end

      it "catches exception from transition" do
        allow(transition_instance).to receive(:process).and_raise(RuntimeError)
        expect(Rails.logger).to receive(:error).with(/Exception/)
        subject.subscribe_to_approval_updates
      end
    end

    context "when the state of the approval is denied" do
      let(:decision)             { "denied" }
      let(:reason)               { "System Denied" }
      let(:approval_request_ref) { "1" }

      it "creates a progress message about the payload" do
        subject.subscribe_to_approval_updates
        latest_progress_message = ProgressMessage.second_to_last
        expect(latest_progress_message.level).to eq("info")
        expect(latest_progress_message.message).to eq("Approval #{approval_request.id} message: #{event_message} decision:  #{decision}")
      end

      it "updates the approval request to be denied" do
        subject.subscribe_to_approval_updates
        approval_request.reload
        expect(approval_request.state).to eq("denied")
      end
    end
  end
end
