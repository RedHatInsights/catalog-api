describe ApprovalRequest, :type => :model do
  let(:order2) { create(:order) }
  let(:portfolio_item) { create(:portfolio_item) }
  let(:order_item1) { create(:order_item, :portfolio_item => portfolio_item) }
  let(:order_item2) { create(:order_item, :portfolio_item => portfolio_item, :order => order2) }
  let!(:approval_request1) { create(:approval_request, :order_item => order_item1) }
  let!(:approval_request2) { create(:approval_request, :order_item => order_item2) }

  around do |example|
    Insights::API::Common::Request.with_request(default_request) { example.call }
  end

  context "by_owner" do
    let(:results) { ApprovalRequest.by_owner }

    before do
      order2.update!(:owner => "not_jdoe")
    end

    it "only has one result" do
      expect(results.size).to eq 1
    end

    it "filters by the owner" do
      expect(results.first.id).to eq approval_request1.id
    end
  end

  describe ".create" do
    it "generates a progress_message on the associated order_item" do
      progress_message = approval_request1.order_item.order.progress_messages.first
      expect(progress_message.message).to match(/Created Approval Request ref: \d*\.  catalog approval request id: #{approval_request1.id}/)
    end
  end
end
