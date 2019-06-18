describe Internal::V1x0::NotifyController, :type => :request do
  describe "POST /notify/:klass/:id" do
    around do |example|
      bypass_rbac do
        example.call
      end
    end

    context "when the class provided is not a supported notification class" do
      let(:klass) { "portfolio" }

      it "returns a 422" do
        post "/internal/v1.0/notify/#{klass}/123", :headers => default_headers, :params => {:payload => {:decision => "test"}.to_json}

        expect(response.status).to eq(422)
      end
    end

    context "when the class provided is supported" do
      let(:klass) { "order_item" }
      let(:tenant) { create(:tenant) }
      let(:order) { create(:order, :tenant_id => tenant.id) }
      let(:portfolio_item) { create(:portfolio_item, :service_offering_ref => "123", :tenant_id => tenant.id) }
      let!(:order_item) { create(:order_item, :order_id => order.id, :portfolio_item_id => portfolio_item.id, :tenant_id => tenant.id) }

      it "returns the object with the updated state" do
        post "/internal/v1.0/notify/#{klass}/#{order_item.id}", :headers => default_headers, :params => {:payload => {:decision => "test"}.to_json}

        json_response = {:notification_object => order_item.reload}.to_json(:prefixes => ["/internal/v1.0/notify"])
        expect(response.body).to eq(json_response)
      end
    end
  end
end
