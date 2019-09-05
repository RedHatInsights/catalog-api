describe ApprovalRequest, :type => :model do
  let(:tenant) { create(:tenant) }
  let(:portfolio) { create(:portfolio, :tenant_id => tenant.id) }
  let(:portfolio_item) { create(:portfolio_item, :portfolio_id => portfolio.id, :tenant_id => tenant.id) }
  let(:order1) { create(:order, :tenant_id => tenant.id) }
  let(:order2) { create(:order, :tenant_id => tenant.id) }
  let(:order_item1) { create(:order_item, :tenant_id => tenant.id, :portfolio_item_id => portfolio_item.id, :order_id => order1.id) }
  let(:order_item2) { create(:order_item, :tenant_id => tenant.id, :portfolio_item_id => portfolio_item.id, :order_id => order2.id) }
  let!(:approval_request1) { create(:approval_request, :order_item_id => order_item1.id, :tenant_id => tenant.id) }
  let!(:approval_request2) { create(:approval_request, :order_item_id => order_item2.id, :tenant_id => tenant.id) }

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
