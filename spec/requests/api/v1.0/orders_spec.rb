describe "v1.0 - OrderRequests", :type => [:request, :v1] do
  let!(:order) { create(:order) }
  let!(:order_item) { create(:order_item, :order => order) }
  let!(:order2) { create(:order) }
  let!(:order_item2) { create(:order_item, :order => order2) }
  let(:catalog_access) { instance_double(Insights::API::Common::RBAC::Access, :scopes => %w[admin]) }
  before do
     allow(Insights::API::Common::RBAC::Access).to receive(:new).and_return(catalog_access)
     allow(catalog_access).to receive(:process).and_return(catalog_access)
  end

  describe "#submit_order" do
    let(:service_offering_service) { instance_double("Api::V1x0::Catalog::ServiceOffering") }
    subject { post "#{api_version}/orders/#{order.id}/submit_order", :headers => default_headers }

    before do
      allow(Api::V1x0::Catalog::ServiceOffering).to receive(:new).with(order).and_return(service_offering_service)
      allow(service_offering_service).to receive(:process).and_return(service_offering_service)
      allow(service_offering_service).to receive(:archived).and_return(archived)
      allow(service_offering_service).to receive(:order).and_return(order)
    end

    context "when the service offering has not been archived" do
      let(:archived) { false }
      let(:svc_object) { instance_double("Catalog::CreateRequestForAppliedInventories") }

      before do |example|
        allow(Api::V1x0::Catalog::CreateRequestForAppliedInventories).to receive(:new).with(order).and_return(svc_object)
        allow(svc_object).to receive(:process).and_return(svc_object)
        allow(svc_object).to receive(:order).and_return(order)
        subject unless example.metadata[:subject_inside]
      end

      it_behaves_like "action that tests authorization", :submit_order?, Order

      it "creates a request for applied inventories", :subject_inside do
        expect(svc_object).to receive(:process)
        subject
      end

      it "returns a 200" do
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
      end

      it "returns the order in json format" do
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["state"]).to eq("Created")
        expect(parsed_body["id"]).to eq(order.id.to_s)
      end
    end

    context "when the service offering has been archived" do
      let(:archived) { true }

      before do |example|
        subject unless example.metadata[:subject_inside]
      end

      it_behaves_like "action that tests authorization", :submit_order?, Order

      it "logs the error", :subject_inside do
        expect(Rails.logger).to receive(:error).twice.with(/Service offering for order #{order.id} has been archived/)
        expect(Rails.logger).to receive(:error).with(/Updated Order: #{order.id} with 'Failed' state message: Order Failed/)

        subject
      end

      it "creates progress messages for the order items" do
        expect(ProgressMessage.first.message).to match(/has been archived/)
        expect(ProgressMessage.last.message).to match(/Order Failed/)
      end

      it "marks the order as failed" do
        order.reload
        expect(order.state).to eq("Failed")
      end

      it "returns a 400" do
        expect(response).to have_http_status(:bad_request)
      end
    end

    context "when the survey has changed" do
      let(:archived) { false }
      let(:req) { {:headers => default_headers, :original_url => "localhost/nope"} }
      let!(:order_item) do
        Insights::API::Common::Request.with_request(req) do
          create(:order_item, :order => order)
        end
      end
      let!(:service_plan) { create(:service_plan, :portfolio_item => order.order_items.first.portfolio_item) }

      before do |example|
        allow(::Catalog::SurveyCompare).to receive(:collect_changed).with(order.order_items.first.portfolio_item.service_plans).and_return([service_plan])

        subject unless example.metadata[:subject_inside]
      end

      it_behaves_like "action that tests authorization", :submit_order?, Order

      it "returns a 400" do
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(400)
        expect(first_error_detail).to match(/Catalog::InvalidSurvey/)

        order.reload
        expect(order.state).to eq("Failed")
      end
    end

    describe "when exceptions are raised" do
      let(:archived) { false }
      shared_examples_for "with errors" do
        it "returns Failed state" do
          subject
          order.reload
          expect(order.state).to eq("Failed")
        end
      end

      context "from service_offering_service" do
        before { allow(service_offering_service).to receive(:process).and_raise(StandardError) }

        it_behaves_like "with errors"
      end

      context "from inventory service" do
        before { allow(CatalogInventory::Service).to receive(:call).and_raise(Catalog::CatalogInventoryError.new("boom")) }

        it_behaves_like "with errors"
      end
    end
  end

  context "#cancel_order" do
    let(:cancel_order) { instance_double("Catalog::CancelOrder", :order => "test") }

    before do
      allow(Api::V1x0::Catalog::CancelOrder).to receive(:new).and_return(cancel_order)
    end

    context "when the order is cancelable" do
      before do
        allow(cancel_order).to receive(:process).and_return(cancel_order)
      end

      it "successfully cancels the order" do
        patch "#{api_version}/orders/#{order.id}/cancel", :headers => default_headers

        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
      end
    end

    context "when the order is not cancelable" do
      before do
        allow(cancel_order).to receive(:process).and_raise(Catalog::OrderUncancelable.new("Order not cancelable"))
      end

      it "returns a 400" do
        patch "#{api_version}/orders/#{order.id}/cancel", :headers => default_headers

        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:bad_request)
        expect(first_error_detail).to match(/Order not cancelable/)
      end
    end
  end

  context "list orders" do
    context "without filter" do
      before do
        get "#{api_version}/orders", :headers => default_headers
      end

      it "returns a 200" do
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
      end

      it "returns them in reversed order" do
        expect(json['data'][0]['id']).to eq(order2.id.to_s)
        expect(json['data'][1]['id']).to eq(order.id.to_s)
      end
    end

    context "with filter" do
      before do
        get "#{api_version}/orders?filter[id]=#{order.id}", :headers => default_headers
      end

      it "follows filter parameter" do
        expect(json['data'].first['id']).to eq order.id.to_s
        expect(json['meta']['count']).to eq 1
      end
    end
  end

  context "create" do
    it "create a new order" do
      post "#{api_version}/orders", :headers => default_headers, :params => {}
      expect(response.content_type).to eq("application/json")
      expect(response).to have_http_status(:ok)
    end
  end

  describe "DELETE /orders/:id" do
    context "when deleting an order is sucessful" do
      before do
        delete "#{api_version}/orders/#{order.id}", :headers => default_headers
      end

      it "deletes the record" do
        expect(response).to have_http_status(:ok)
      end

      it "sets the discarded_at column" do
        expect(Order.with_discarded.find_by(:id => order.id).discarded_at).to_not be_nil
      end

      it "returns the restore_key in the body" do
        expect(json["restore_key"]).to eq Digest::SHA1.hexdigest(Order.with_discarded.find(order.id).discarded_at.to_s)
      end
    end

    context "when deleting an order where a linked order item fails" do
      let!(:order_item) { create(:order_item, :order_id => order.id, :portfolio_item_id => portfolio_item.id) }
      let(:portfolio_item) { create(:portfolio_item, :service_offering_ref => "123") }

      before do
        order.order_items << order_item
        allow(Order).to receive(:find).with(order.id.to_s).and_return(order)
        allow(order_item).to receive(:discard).and_return(false)
        delete "#{api_version}/orders/#{order.id}", :headers => default_headers
      end

      it "returns a 400" do
        expect(response).to have_http_status(:bad_request)
      end

      it "does not delete the order" do
        expect(Order.where(:id => order.id).first).to eq(order)
      end
    end

    context "when deleting an order where a linked order item has linked progress messages that fail" do
      let!(:order_item) { create(:order_item, :order_id => order.id, :portfolio_item_id => portfolio_item.id) }
      let!(:progress_message) { create(:progress_message, :order_item_id => order_item.id) }
      let(:portfolio_item) { create(:portfolio_item, :service_offering_ref => "123") }

      before do
        order.order_items << order_item
        order_item.progress_messages << progress_message
        allow(Order).to receive(:find).with(order.id.to_s).and_return(order)
        allow(progress_message).to receive(:discard).and_return(false)
        delete "#{api_version}/orders/#{order.id}", :headers => default_headers
      end

      it "returns a 400" do
        expect(response).to have_http_status(:bad_request)
      end

      it "does not delete the order" do
        expect(Order.where(:id => order.id).first).to eq(order)
      end
    end
  end

  describe "POST /orders/:id/restore" do
    let(:restore_key) { Digest::SHA1.hexdigest(order.discarded_at.to_s) }
    let(:params) { {:restore_key => restore_key} }

    context "when restoring an order is successful" do
      before do
        order.discard
        post "#{api_version}/orders/#{order.id}/restore", :headers => default_headers, :params => params
      end

      it "returns a 200" do
        expect(response).to have_http_status :ok
      end

      it "returns the restored record" do
        expect(json["id"]).to eq order.id.to_s
      end
    end

    context "when restoring an order with the wrong restore key" do
      let(:restore_key) { "MrMaliciousRestoreKey" }

      before do
        order.discard
        post "#{api_version}/orders/#{order.id}/restore", :headers => default_headers, :params => params
      end

      it "returns a 403" do
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when restoring an order where a linked order item fails to be restored" do
      let!(:order_item) { create(:order_item, :order_id => order.id, :portfolio_item_id => portfolio_item.id) }
      let(:portfolio_item) { create(:portfolio_item, :service_offering_ref => "123") }

      before do
        order.order_items << order_item
        order.discard
        allow(Order).to receive_message_chain(:with_discarded, :discarded, :find).with(order.id.to_s).and_return(order)
        allow(order).to receive_message_chain(:order_items, :with_discarded, :discarded).and_return([order_item])
        allow(order_item).to receive(:undiscard).and_return(false)
        post "#{api_version}/orders/#{order.id}/restore", :headers => default_headers, :params => params
      end

      it "returns a 400" do
        expect(response).to have_http_status(:bad_request)
      end

      it "does not restore the order" do
        expect(Order.where(:id => order.id).first).to be_nil
      end
    end

    context "when restoring an order where a linked order item with a linked progress message fails to be restored" do
      let!(:order_item) { create(:order_item, :order_id => order.id, :portfolio_item_id => portfolio_item.id) }
      let!(:progress_message) { create(:progress_message, :order_item_id => order_item.id) }
      let(:portfolio_item) { create(:portfolio_item, :service_offering_ref => "123") }

      before do
        order.order_items << order_item
        order_item.progress_messages << progress_message
        order.discard
        allow(Order).to receive_message_chain(:with_discarded, :discarded, :find).with(order.id.to_s).and_return(order)
        allow(order).to receive_message_chain(:order_items, :with_discarded, :discarded).and_return([order_item])
        allow(order_item).to receive_message_chain(:progress_messages, :with_discarded, :discarded).and_return([progress_message])
        allow(progress_message).to receive(:undiscard).and_return(false)
        post "#{api_version}/orders/#{order.id}/restore", :headers => default_headers, :params => params
      end

      it "returns a 400" do
        expect(response).to have_http_status(:bad_request)
      end

      it "does not restore the order" do
        expect(Order.where(:id => order.id).first).to be_nil
      end
    end
  end
end
