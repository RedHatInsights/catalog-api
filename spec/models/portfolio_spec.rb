describe Portfolio do
  let(:portfolio)      { create(:portfolio, :without_tenant) }
  let(:portfolio_item) { create(:portfolio_item, :without_tenant) }
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

      it "does not scope tenant_id on a portfolio lookup" do
        expect(portfolio.tenant_id).to be_nil
        expect(Portfolio.all.map(&:tenant_id)).to eq [nil]
      end
    end
  end

  context "with and without current_tenant" do
    let(:portfolio_two) { create(:portfolio) }
    let(:tenant_two)    { create(:tenant) }
    describe "#add_portfolio_item" do
      before do
        ActsAsTenant.current_tenant = tenant_two
        portfolio_two
        ActsAsTenant.current_tenant = tenant
        portfolio
      end

      it "only finds a portfolio scoped to the current_tenant" do
          ActsAsTenant.current_tenant = nil
          expect(Portfolio.all.count).to eq 2

          ActsAsTenant.current_tenant = tenant
          expect(Portfolio.all.count).to eq 1
          expect(Portfolio.first.tenant_id).to eq tenant.id

          ActsAsTenant.current_tenant = tenant_two
          expect(Portfolio.all.count).to eq 1
          expect(Portfolio.first.tenant_id).to eq tenant_two.id
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

      it "defines a scoped tenant_id on a portfolio lookup" do
        expect(portfolio.tenant_id).to_not be_nil
        expect(Portfolio.all.map(&:tenant_id)).to eq [tenant.id]
      end
    end
  end
end
