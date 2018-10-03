describe Portfolio do
  let(:portfolio)      { create(:portfolio) }
  let(:portfolio_item) { create(:portfolio_item) }
  let(:tenant)         { create(:tenant) }

  context "without current_tenant" do

    before do
      ActsAsTenant.current_tenant = nil
    end

    describe "#add_portfolio_item" do
      it "has no tenant set" do
        expect(portfolio.tenant_id).to be_nil
        expect(portfolio_item.tenant_id).to be_nil
      end

      it "returns the last added portfolio_item" do
        expect(portfolio.add_portfolio_item(portfolio_item.id).first).to be_a PortfolioItem
      end

      it "adds the portfolio_item passed into the method" do
        expect(portfolio.tenant_id).to be_nil
        expect(portfolio.add_portfolio_item(portfolio_item.id).first.id).to eq portfolio_item.id
      end
    end
  end

  context "with current_tenant" do

    before do
      ActsAsTenant.current_tenant = tenant
    end

    describe "#add_portfolio_item" do
      it "has a tenant set" do
        expect(portfolio.tenant_id).to eq tenant.id
        expect(portfolio_item.tenant_id).to eq tenant.id
      end

      it "returns the last added portfolio_item with a tenant" do
        expect(portfolio.add_portfolio_item(portfolio_item.id).first.tenant_id).to eq tenant.id
      end

      it "adds the portfolio_item passed into the method with a tenant" do
        expect(portfolio.add_portfolio_item(portfolio_item.id).first.tenant_id).to eq tenant.id
      end
    end
  end
end
