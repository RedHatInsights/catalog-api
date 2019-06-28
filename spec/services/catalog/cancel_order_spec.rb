describe Catalog::CancelOrder do
  let(:order) { create(:order) }
  let(:portfolio_item) { create(:portfolio_item) }
  let(:order_item) { create(:order_item, :order_id => order.id, :portfolio_item_id => portfolio_item.id) }
  let!(:approval_request) { create(:approval_request, :order_item_id => order_item.id) }
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
        expect { subject.process }.to raise_exception(Catalog::OrderUncancelable)
      end
    end

    describe "when the state of the order is Failed" do
      let(:state) { "Failed" }

      it "raises an error" do
        expect { subject.process }.to raise_exception(Catalog::OrderUncancelable)
      end
    end

    describe "when the state of the order is anything else" do
      let(:state) { "Pending" }
      let(:cancel_order_url) { "http://localhost/api/approval/v1.0/requests/#{approval_request.id}/actions" }

      before do
        stub_request(:post, cancel_order_url).with(:body => {"operation" => "cancel"})
      end

      it "calls the approval api" do
        subject.process
        expect(a_request(:post, cancel_order_url).with(:body => {"operation" => "cancel"})).to have_been_made
      end
    end
  end
end
