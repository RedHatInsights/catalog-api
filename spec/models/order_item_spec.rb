describe OrderItem do
  let(:order_item) { create(:order_item) }

  context "updating order item progress messages" do
    it "syncs the time between order_item and progress message" do
      order_item.update_message("test_level", "test message")
      order_item.reload
      last_message = order_item.progress_messages.last
      expect(order_item.updated_at).to be_a(Time)
      expect(last_message.messageable_id.to_i).to eq(order_item.id)
      expect(last_message.messageable_type).to eq(order_item.class.name)
      expect(last_message.tenant_id).to eq(order_item.tenant.id)
    end
  end

  describe "#discard before hook" do
    context "when the order item has progress messages" do
      let(:progress_message) { create(:progress_message, :order_item_id => order_item.id) }

      it "destroys progress_messages associated with the order" do
        order_item.progress_messages << progress_message
        order_item.discard
        expect(OrderItem.find_by(:id => order_item.id)).to be_nil
        expect(ProgressMessage.find_by(:id => progress_message.id)).to be_nil
      end
    end
  end

  describe "#undiscard before hook" do
    context "when the order item has progress messages" do
      let(:progress_message) { create(:progress_message, :order_item_id => order_item.id) }

      before do
        order_item.progress_messages << progress_message
        order_item.save
        order_item.discard
      end

      it "restores the order items associated with the order" do
        expect(OrderItem.find_by(:id => order_item.id)).to be_nil
        expect(ProgressMessage.find_by(:id => progress_message.id)).to be_nil
        order_item = OrderItem.with_discarded.discarded.first
        order_item.undiscard
        expect(OrderItem.find_by(:id => order_item.id)).to_not be_nil
        expect(ProgressMessage.find_by(:id => progress_message.id)).to_not be_nil
      end
    end
  end

  shared_examples_for "#mark_item" do
    it "sets the params properly" do
      params.each do |k, v|
        expect(order_item.send(k)).to eq v
      end
    end
  end

  describe "#mark_completed" do
    let(:params) { {:external_url => "not.a.real/url"} }

    before do
      allow(Catalog::SubmitNextOrderItem).to receive(:new).with(order_item.order_id).and_return(double(:process => nil))

      order_item.mark_completed(params)
      order_item.reload
    end

    it "marks the order and order item as completed" do
      expect(order_item.state).to eq "Completed"
      expect(order_item.order.state).to eq "Completed"
      expect(order_item.completed_at).to be_truthy
    end

    it_behaves_like "#mark_item"
  end

  describe "#mark_failed" do
    context "when there are no message parameters passed in" do
      let(:params) { {:external_url => "not.a.real/url"} }

      before do
        allow(Catalog::SubmitNextOrderItem).to receive(:new).with(order_item.order_id).and_return(double(:process => nil))

        order_item.mark_failed(params)
        order_item.reload
      end

      it "marks the order and order item as failed" do
        expect(order_item.state).to eq "Failed"
        expect(order_item.order.state).to eq "Failed"
        expect(order_item.completed_at).to be_truthy
      end

      it_behaves_like "#mark_item"

      it "finalizes the order" do
        expect(order_item.order.state).to eq("Failed")
      end
    end

    context "when there are no message parameters passed in" do
      it "does not log a message" do
        expect(Rails.logger).not_to receive(:error)
        order_item.mark_failed
      end
    end
  end

  describe "#mark_ordered" do
    let(:params) { {:topology_task_ref => "an id", :external_url => "not.a.real/url"} }

    before do
      order_item.mark_ordered(params)
      order_item.reload
    end

    it "marks the order and order item as failed" do
      expect(order_item.state).to eq "Ordered"
      expect(order_item.order.state).to eq "Ordered"
      expect(order_item.completed_at).to be_falsey
    end

    it_behaves_like "#mark_item"
  end

  describe '#can_order?' do
    before { order_item.update(:process_scope => process_scope, :state => state) }

    context 'when process_scope is product' do
      let(:process_scope) { 'product' }

      context 'when state is Approved' do
        let(:state) { 'Approved' }

        it 'is orderable' do
          expect(order_item.can_order?).to be_truthy
        end
      end

      context 'when state is not Approved' do
        let(:state) { 'Create' }

        it 'is not orderable' do
          expect(order_item.can_order?).to be_falsey
        end
      end
    end

    context 'when process_scope is before' do
      let(:process_scope) { 'before' }

      context 'when state is Created' do
        let(:state) { 'Created' }

        it 'is orderable' do
          expect(order_item.can_order?).to be_truthy
        end
      end

      context 'when state is not Created' do
        let(:state) { 'Ordered' }

        it 'is not orderable' do
          expect(order_item.can_order?).to be_falsey
        end
      end
    end

    context 'when process_scope is after' do
      let(:process_scope) { 'after' }

      context 'when state is Created' do
        let(:state) { 'Created' }

        it 'is orderable' do
          expect(order_item.can_order?).to be_truthy
        end
      end

      context 'when stae is not Created' do
        let(:state) { 'Completed' }

        it 'is not orderable' do
          expect(order_item.can_order?).to be_falsey
        end
      end
    end
  end

  describe 'sanitize parameters before an order_item is saved' do
    let(:order_item) { create(:order_item_with_callback, :service_parameters => {'key' => 'val'}) }
    let(:order_item_sanitized_parameters) { instance_double(Catalog::OrderItemSanitizedParameters, :process => double(:sanitized_parameters => sanitized_parameters)) }
    before { allow(Catalog::OrderItemSanitizedParameters).to receive(:new).and_return(order_item_sanitized_parameters) }

    context 'when parameters need sanitizing' do
      let(:sanitized_parameters) { {'key' => '$protected$'} }

      it 'copies original parameters to service_parameters_raw' do
        expect(order_item.service_parameters).to eq('key' => '$protected$')
        expect(order_item.service_parameters_raw).to eq('key' => 'val')
      end
    end

    context 'when parameters do not need sanitizing' do
      let(:sanitized_parameters) { {'key' => 'val'} }

      it 'leaves service_parameters_raw empty' do
        expect(order_item.service_parameters).to eq('key' => 'val')
        expect(order_item[:service_parameters_raw]).to be_nil
      end
    end
  end

  describe '#service_parameters_raw' do
    context 'when sensitive service_parameters present' do
      before do
        order_item[:service_parameters_raw] = 'some value'
        order_item.save
      end

      it 'returns internal service_parameters_raw' do
        expect(order_item.service_parameters_raw).to eq('some value')
      end

      describe '#clear_sensitive_service_parameters' do
        it 'clears sensitive service parameters' do
          expect(order_item[:service_parameters_raw]).to eq('some value')
          order_item.clear_sensitive_service_parameters
          order_item.reload
          expect(order_item[:service_parameters_raw]).to be_nil
        end
      end
    end

    context 'when no service_parameters present' do
      it 'returns service_parameters' do
        expect(order_item.service_parameters).to eq("name" => "fred")
        expect(order_item.service_parameters_raw).to eq("name" => "fred")
      end
    end
  end
end
