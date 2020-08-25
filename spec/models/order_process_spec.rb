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

  context "name validation" do
    let(:order_process1_copy) { create(:order_process, :tenant_id => tenant_id) }

    before do
      order_process1.update(:name => "dup")
      order_process1_copy.update(:name => "dup")
    end

    context "when the tenant is the same" do
      let(:tenant_id) { tenant1.id }

      it "fails validation" do
        expect(order_process1).to be_valid
        expect(order_process1_copy).to_not be_valid
        expect(order_process1_copy.errors.messages[:name]).to eq(["has already been taken"])
      end
    end

    context "when the tenant is different" do
      let(:tenant_id) { tenant2.id }

      it "passes validation" do
        expect(order_process1).to be_valid
        expect(order_process1_copy).to be_valid
      end
    end
  end
end
