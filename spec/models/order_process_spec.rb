describe OrderProcess do
  let(:tenant1) { create(:tenant, :external_tenant => "1") }
  let(:tenant2) { create(:tenant, :external_tenant => "2") }
  let!(:order_process1) { create(:order_process, :tenant => tenant1) }

  it { is_expected.to have_many(:tag_links) }

  it ".taggable?" do
    expect(OrderProcess.taggable?).to be_truthy
  end

  context "with tenants" do
    let!(:order_process2) { create(:order_process, :tenant => tenant2) }

    it "only returns order_process with current tenant" do
      ActsAsTenant.without_tenant do
        expect(OrderProcess.count).to eq(2)
      end

      ActsAsTenant.with_tenant(tenant1) do
        expect(OrderProcess.count).to eq(1)
        expect(OrderProcess.first.tenant_id).to eq(tenant1.id)
      end
    end
  end
end
