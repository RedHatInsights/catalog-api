describe ApprovalRequest, :type => :model do
  let(:order2) { create(:order) }
  let(:portfolio_item) { create(:portfolio_item) }
  let(:order_item1) { create(:order_item, :portfolio_item => portfolio_item) }
  let(:order_item2) { create(:order_item, :portfolio_item => portfolio_item, :order => order2) }
  let!(:approval_request1) { create(:approval_request, :order_item => order_item1) }
  let!(:approval_request2) { create(:approval_request, :order_item => order_item2) }

  around do |example|
    ManageIQ::API::Common::Request.with_request(default_request) { example.call }
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
end
