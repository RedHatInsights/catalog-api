describe Order do
  let(:tenant) { create(:tenant) }
  let!(:order1) { create(:order, :tenant_id => tenant.id) }
  let!(:order2) { create(:order, :tenant_id => tenant.id) }
  let!(:order3) { create(:order, :tenant_id => tenant.id, :owner => 'barney') }

  context "scoped by owner" do
    it "#by_owner" do
      ManageIQ::API::Common::Request.with_request(default_request) do
        expect(Order.by_owner.collect(&:id)).to match_array([order1.id, order2.id])
        expect(Order.all.count).to eq(3)
      end
    end
  end
end
