describe "ProgressMessageRequests", :type => :request do
  around do |example|
    bypass_rbac do
      example.call
    end
  end

  let(:tenant) { create(:tenant) }
  let(:order) { create(:order, :tenant_id => tenant.id) }
  let!(:order_item) { create(:order_item, :order_id => order.id, :portfolio_item_id => portfolio_item.id, :tenant_id => tenant.id) }
  let(:portfolio_item) { create(:portfolio_item, :service_offering_ref => "123", :tenant_id => tenant.id) }
  let!(:progress_message) { create(:progress_message, :order_item_id => order_item.id.to_s, :tenant_id => tenant.id) }

  context "v1.0" do
    describe "GET /order_items/:order_item_id/progress_messages" do
      it "lists progress messages" do
        get "/#{api}/order_items/#{order_item.id}/progress_messages", :headers => default_headers

        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['data'].first['message']).to eq(progress_message.message)
      end

      context "when the order item does not exist" do
        let(:order_item_id) { 0 }

        it "returns a 404" do
          get "/#{api}/order_items/#{order_item_id}/progress_messages", :headers => default_headers

          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(JSON.parse(response.body)['message']).to eq("Not Found")
        end
      end
    end

    describe "DELETE /order_items/:order_item_id/progress_messages/:id" do
      before do
        delete "/#{api}/order_items/#{order_item.id}/progress_messages/#{progress_message.id}", :headers => default_headers
      end

      it "deletes the record" do
        expect(response).to have_http_status(:ok)
      end

      it "sets the discarded_at column" do
        expect(ProgressMessage.with_discarded.find_by(:id => progress_message.id).discarded_at).to_not be_nil
      end

      it "returns the restore_key in the body" do
        expect(json["restore_key"]).to eq Digest::SHA1.hexdigest(ProgressMessage.with_discarded.find(progress_message.id).discarded_at.to_s)
      end
    end

    describe "POST /order_items/:order_item_id/progress_messages/:id/restore" do
      let(:restore_key) { Digest::SHA1.hexdigest(progress_message.discarded_at.to_s) }
      let(:params) { {:restore_key => restore_key} }

      before do
        progress_message.discard
        post "/#{api}/order_items/#{order_item.id}/progress_messages/#{progress_message.id}/restore",
          :headers => default_headers,
          :params  => params
      end

      context "when restoring a progress_message is successful" do
        it "returns a 200" do
          expect(response).to have_http_status :ok
        end

        it "returns the restored record" do
          expect(json["order_item_id"]).to eq progress_message.order_item_id.to_s
          expect(json["message"]).to eq progress_message.message.to_s
        end
      end

      context "when restoring a progress_message with the wrong restore key" do
        let(:restore_key) { "MrMaliciousRestoreKey" }

        it "returns a 403" do
          expect(response).to have_http_status(:forbidden)
        end
      end
    end
  end
end
