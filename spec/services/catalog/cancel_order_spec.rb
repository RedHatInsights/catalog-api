describe Catalog::CancelOrder do
  let(:tenant) { create(:tenant) }
  let(:portfolio) { create(:portfolio, :tenant_id => tenant.id) }
  let(:portfolio_item) { create(:portfolio_item, :portfolio_id => portfolio.id, :tenant_id => tenant.id) }
  let(:order) { create(:order, :tenant_id => tenant.id) }
  let(:order_item) { create(:order_item, :tenant_id => tenant.id, :order_id => order.id, :portfolio_item_id => portfolio_item.id) }
  let!(:approval_request) { create(:approval_request, :order_item_id => order_item.id, :tenant_id => tenant.id) }
  let(:subject) { described_class.new(order.id) }

  describe "#process" do
    around do |example|
      with_modified_env(:APPROVAL_URL => "http://localhost") do
        example.call
      end
    end

    before do
      order.update(:state => state)
      allow(ManageIQ::API::Common::Request).to receive(:current_forwardable).and_return(default_headers)
    end

    describe "when the state of the order is Completed" do
      let(:state) { "Completed" }

      it "raises an error" do
        expect { subject.process }.to raise_exception(Catalog::OrderUncancelable, "Order #{order.id} is not cancelable in its current state: #{order.state}")
      end
    end

    describe "when the state of the order is Failed" do
      let(:state) { "Failed" }

      it "raises an error" do
        expect { subject.process }.to raise_exception(Catalog::OrderUncancelable, "Order #{order.id} is not cancelable in its current state: #{order.state}")
      end
    end

    describe "when the state of the order is Ordered" do
      let(:state) { "Ordered" }

      it "raises an error" do
        expect { subject.process }.to raise_exception(Catalog::OrderUncancelable, "Order #{order.id} is not cancelable in its current state: #{order.state}")
      end
    end

    describe "when the state of the order is anything else" do
      let(:state) { "Pending" }
      let(:cancel_order_url) { "http://localhost/api/approval/v1.0/requests/#{approval_request.approval_request_ref}/actions" }

      before do
        stub_request(:post, cancel_order_url).with(:body => {"operation" => "cancel"}).to_return(api_response)
      end

      context "when the request returns a 200" do
        let(:api_response) { {:status => 200} }

        it "calls the approval api" do
          subject.process
          expect(a_request(:post, cancel_order_url).with(:body => {"operation" => "cancel"})).to have_been_made
        end
      end

      context "when the request returns a 500" do
        let(:api_response) { {:status => 500} }

        it "rescues the exception" do
          expect { subject.process }.to raise_exception(Catalog::OrderUncancelable)
        end
      end
    end
  end
end
