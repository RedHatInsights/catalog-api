describe Portfolio do
  let(:portfolio)          { create(:portfolio, :without_tenant) }
  let(:portfolio_id)       { portfolio.id }
  let(:portfolio_item)     { create(:portfolio_item, :without_tenant) }
  let(:portfolio_item_id)  { portfolio_item.id }
  let(:tenant)             { create(:tenant) }

  context "when setting portfolio fields" do
    it "fails validation with a bad uri" do
      portfolio.image_url = "notreallyaurl"
      expect(portfolio).to_not be_valid
    end

    it "fails validation with a non %w(true false) value" do
      portfolio.enabled = "tralse"
      expect(portfolio).to_not be_valid
    end
  end

  context "destroy portfolio cascading portfolio_items" do
    before do
      ActsAsTenant.current_tenant = nil
      portfolio.add_portfolio_item(portfolio_item)
    end

    it "destroys portfolio_items only associated with the current portfolio" do
      portfolio.destroy
      expect(Portfolio.find_by(:id => portfolio_id)).to be_nil
      expect(PortfolioItem.find_by(:id => portfolio_item_id)).to be_nil
    end
  end

  context "when updating a portfolio" do
    let(:workflow_ref) { Time.now.to_i }
    before do
      ActsAsTenant.current_tenant = tenant
    end

    it "will allow adding a workflow_ref" do
      expect(portfolio.update(:workflow_ref => workflow_ref)).to be_truthy
      expect(portfolio.workflow_ref).to eq workflow_ref.to_s
    end
  end

  context "when a tenant tries to create portfolios with the same name" do
    let(:portfolio_copy) { create(:portfolio, :without_tenant) }

    before do
      ActsAsTenant.current_tenant = tenant
    end

    it "will fail validation" do
      portfolio.update(:name => "samename")
      portfolio_copy.update(:name => "samename")

      expect(portfolio).to be_valid
      expect(portfolio_copy).to_not be_valid
      expect(portfolio_copy.errors.messages[:name]).to_not be_nil

      expect{ portfolio_copy.save! }.to raise_exception(ActiveRecord::RecordInvalid)
    end
  end

  context "when different tenants try to create portfolios with the same name" do
    let(:portfolio_copy) { create(:portfolio, :without_tenant) }
    let(:second_tenant)  { create(:tenant) }

    before do
      ActsAsTenant.current_tenant = tenant
    end

    it "will pass validation" do
      portfolio.update(:name => "samename")
      ActsAsTenant.current_tenant = second_tenant
      portfolio_copy.update(:name => "samename")

      expect(portfolio).to be_valid
      expect(portfolio_copy).to be_valid

      expect{ portfolio_copy.save! }.to_not raise_error
    end
  end

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
