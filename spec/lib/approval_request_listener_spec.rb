describe ApprovalRequestListener do
  let(:approval_request_ref) { "0" }
  let(:client)               { double(:client) }
  let(:event)                { ApprovalRequestListener::EVENT_REQUEST_FINISHED }
  let(:payload)              { { "request_id" => request_id, "decision" => decision, "reason" => reason } }
  let(:request_id)           { "1" }

  let(:so) { class_double(Catalog::SubmitOrder).as_stubbed_const(:transfer_nested_constants => true) }
  let(:so_instance) { instance_double(Catalog::SubmitOrder) }
  let(:topo_ex) { Catalog::TopologyError.new("kaboom") }

  describe "#subscribe_to_approval_updates" do
    let(:message)     { ManageIQ::Messaging::ReceivedMessage.new(nil, event, payload, nil) }
    let(:order) { create(:order) }
    let!(:order_item) do
      create(:order_item,
             :order_id          => order.id,
             :portfolio_item_id => "234",
             :context           => {
               :headers => encoded_user_hash, :original_url => "localhost/nope"
             })
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

      allow(so).to receive(:new).and_return(so_instance)
      allow(so_instance).to receive(:process).and_return(so_instance)
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
        expect(latest_progress_message.message).to eq("Approval #{approval_request.id} #{decision}")
      end

      it "updates the approval request to be approved" do
        subject.subscribe_to_approval_updates
        approval_request.reload
        expect(approval_request.state).to eq("approved")
      end

      it "submits the order" do
        expect(so_instance).to receive(:process).once
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
        expect(latest_progress_message.message).to eq("Approval #{approval_request.id} #{decision}")
      end

      it "updates the approval request to be denied" do
        subject.subscribe_to_approval_updates
        approval_request.reload
        expect(approval_request.state).to eq("denied")
      end

      it "does not submit the order" do
        expect(so_instance).to receive(:process).exactly(0).times
        subject.subscribe_to_approval_updates
      end

      it "marks the order_item as denied" do
        subject.subscribe_to_approval_updates
        order_item.reload
        expect(order_item.state).to eq "Denied"
      end
    end

    context "when submitting an order fails" do
      let(:decision)             { "approved" }
      let(:reason)               { "System Approved" }
      let(:approval_request_ref) { "1" }

      before do
        allow(so_instance).to receive(:process).and_raise(topo_ex)
      end

      it "blows up" do
        subject.subscribe_to_approval_updates
        latest_progress_message = ProgressMessage.last
        expect(latest_progress_message.level).to eq("info")
        expect(latest_progress_message.message).to eq "Error Submitting Order #{order.id}, #{topo_ex.message}"
      end
    end
  end
end
