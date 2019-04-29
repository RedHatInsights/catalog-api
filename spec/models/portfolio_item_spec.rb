describe PortfolioItem do
  let(:tenant) { create(:tenant) }
  let(:item) { PortfolioItem.new(:tenant_id => tenant.id) }

  let(:service_offering_ref) { "1" }
  let(:owner) { 'wilma' }

  context "requires a service_offering_ref" do
    before do
      item.owner = owner
    end

    it "is not valid without a service_offering_ref" do
      expect(item).to_not be_valid
    end

    it "is valid when we set a service_offering_ref" do
      item.service_offering_ref = service_offering_ref
      expect(item).to be_valid
    end
  end

  context "requires an owner" do
    before do
      item.service_offering_ref = service_offering_ref
    end

    it "is not valid without an owner" do
      expect(item).to_not be_valid
    end

    it "is valid when we set an owner" do
      item.owner = owner
      expect(item).to be_valid
    end
  end

  context "#item_workflow_ref" do
    let(:item_workflow_ref) { "portfolio_item_workflow_ref" }
    let(:portfolio_workflow_ref) { "portfolio_workflow_ref" }
    let(:portfolio) { create(:portfolio, :workflow_ref => portfolio_workflow_ref, :tenant_id => tenant.id) }

    let(:portfolio_item) do
      create(:portfolio_item,
             :service_offering_ref => "123",
             :portfolio_id         => portfolio.id,
             :workflow_ref         => item_workflow_ref,
             :tenant_id            => tenant.id)
    end

    let(:ref) { portfolio_item.send(:item_workflow_ref) }

    context "when the portfolio_item has a workflow_ref" do
      it "returns the portfolio_item's workflow ref" do
        expect(ref).to eq item_workflow_ref
      end
    end

    context "when the portfolio_item is missing the workflow ref" do
      before do
        portfolio_item.update(:workflow_ref => nil)
      end

      it "looks up the workflow_ref on the portfolio" do
        expect(ref).to eq portfolio_workflow_ref
      end
    end

    context "when niether the portfolio item nor portfolio have a workflow_ref" do
      before do
        portfolio_item.update(:workflow_ref => nil)
        portfolio.update(:workflow_ref => nil)
      end

      it "returns nil without throwing an error" do
        expect(ref).to be_nil
      end
    end
  end
end
