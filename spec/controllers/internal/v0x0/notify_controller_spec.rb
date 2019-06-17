describe Internal::V0x0::NotifyController, :type => :request do
  describe "POST /notify/:klass/:id" do
    around do |example|
      bypass_rbac do
        example.call
      end
    end

    context "when the class provided is not a supported notification class" do
      let(:klass) { "portfolio" }

      it "returns a 422" do
        post "/internal/v0.0/notify/#{klass}/123", :headers => default_headers

        expect(response.status).to eq(422)
      end
    end

    context "when the class provided is supported" do
      let(:klass) { "order_item" }
      let(:tenant) { create(:tenant) }
      let(:order) { create(:order, :tenant_id => tenant.id) }
      let(:portfolio_item) { create(:portfolio_item, :service_offering_ref => "123", :tenant_id => tenant.id) }
      let!(:order_item) { create(:order_item, :order_id => order.id, :portfolio_item_id => portfolio_item.id, :tenant_id => tenant.id) }

      it "returns the object" do
        post "/internal/v0.0/notify/#{klass}/#{order_item.id}", :headers => default_headers, :params => {:payload => {:decision => "test"}.to_json}

        expect(response.body).to eq(order_item)
      end
    end
  end
end
