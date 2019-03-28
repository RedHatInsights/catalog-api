describe OrderItem do
  let(:item) { create(:order_item, :order_id => 1, :portfolio_item_id => 1) }
  let!(:approval) { create(:approval_request, :order_item_id => item.id, :state => "approved", :workflow_ref => "0") }

  describe "#approved?" do
    it "returns true when approvals are all approved" do
      expect(item.approved?).to be_truthy
    end

    it "returns false if one is approved and the other is not" do
      create(:approval_request, :order_item_id => item.id, :state => "undecided", :workflow_ref => "0")
      expect(item.approved?).to be_falsey
    end
  end

  describe "#denied?" do
    before do
      create(:approval_request, :order_item_id => item.id, :state => "denied", :workflow_ref => "0")
    end

    it "returns true if any approvals are denied" do
      expect(item.denied?).to be_truthy
    end
  end
end
