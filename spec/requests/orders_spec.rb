describe "OrderRequests", :type => :request do
  around do |example|
    bypass_rbac do
      example.call
    end
  end

  let!(:order) { create(:order) }
  let!(:order2) { create(:order) }

  describe "#submit_order" do
    let(:service_offering_service) { instance_double("Catalog::ServiceOffering") }
    let(:service_offering) { TopologicalInventoryApiClient::ServiceOffering.new(:archived_at => archived_at) }

    before do
      allow(Catalog::ServiceOffering).to receive(:new).with(order.id.to_s).and_return(service_offering_service)
      allow(service_offering_service).to receive(:process).and_return(service_offering_service)
      allow(service_offering_service).to receive(:archived).and_return(archived)
      allow(service_offering_service).to receive(:order).and_return(order)
    end

    context "when the service offering has not been archived" do
      let(:archived) { false }
      let(:svc_object) { instance_double("Catalog::CreateRequestForAppliedInventories") }

      before do
        allow(Catalog::CreateRequestForAppliedInventories).to receive(:new).with(order).and_return(svc_object)
        allow(svc_object).to receive(:process).and_return(svc_object)
        allow(svc_object).to receive(:order).and_return(order)
      end

      it "creates a request for applied inventories" do
        expect(svc_object).to receive(:process)
        post "#{api}/orders/#{order.id}/submit_order", :headers => default_headers
      end

      it "returns a 200" do
        post "#{api}/orders/#{order.id}/submit_order", :headers => default_headers

        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
      end

      it "returns the order in json format" do
        post "#{api}/orders/#{order.id}/submit_order", :headers => default_headers

        parsed_body = JSON.parse(response.body)
        expect(parsed_body["state"]).to eq("Created")
        expect(parsed_body["id"]).to eq(order.id.to_s)
      end
    end

    context "when the service offering has been archived" do
      let(:archived) { true }

      it "raises an exception and gives a 400" do
        post "#{api}/orders/#{order.id}/submit_order", :headers => default_headers

        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  context "#cancel_order" do
    let(:cancel_order) { instance_double("Catalog::CancelOrder", :order => "test") }

    before do
      allow(Catalog::CancelOrder).to receive(:new).and_return(cancel_order)
    end

    context "when the order is cancelable" do
      before do
        allow(cancel_order).to receive(:process).and_return(cancel_order)
      end

      it "successfully cancels the order" do
        patch "/api/v1.0/orders/#{order.id}/cancel", :headers => default_headers

        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
      end
    end

    context "when the order is not cancelable" do
      before do
        allow(cancel_order).to receive(:process).and_raise(Catalog::OrderUncancelable.new("Order not cancelable"))
      end

      it "returns a 400" do
        patch "/api/v1.0/orders/#{order.id}/cancel", :headers => default_headers

        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:bad_request)
        expect(first_error_detail).to match(/Order not cancelable/)
      end
    end
  end

  context "list orders" do
    context "without filter" do
      before do
        get "/api/v1.0/orders", :headers => default_headers
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
        get "/api/v1.0/orders?filter[id]=#{order.id}", :headers => default_headers
      end

      it "follows filter parameter" do
        expect(json['data'].first['id']).to eq order.id.to_s
        expect(json['meta']['count']).to eq 1
      end
    end
  end

  context "create" do
    it "create a new order" do
      post "/api/v1.0/orders", :headers => default_headers, :params => {}
      expect(response.content_type).to eq("application/json")
      expect(response).to have_http_status(:ok)
    end
  end

  describe "DELETE /orders/:id" do
    context "when deleting an order is sucessful" do
      before do
        delete "/#{api}/orders/#{order.id}", :headers => default_headers
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
        delete "/#{api}/orders/#{order.id}", :headers => default_headers
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
        delete "/#{api}/orders/#{order.id}", :headers => default_headers
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
        post "/#{api}/orders/#{order.id}/restore", :headers => default_headers, :params => params
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
        post "/#{api}/orders/#{order.id}/restore", :headers => default_headers, :params => params
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
        post "/#{api}/orders/#{order.id}/restore", :headers => default_headers, :params => params
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
        post "/#{api}/orders/#{order.id}/restore", :headers => default_headers, :params => params
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
