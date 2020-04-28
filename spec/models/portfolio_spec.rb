require "models/concerns/aceable_shared"
describe Portfolio do
  let(:tenant1)           { create(:tenant, :external_tenant => "1") }
  let(:tenant2)           { create(:tenant, :external_tenant => "2") }
  let(:portfolio)         { create(:portfolio, :tenant_id => tenant1.id) }
  let(:portfolio_id)      { portfolio.id }
  let!(:portfolio_item)   { create(:portfolio_item, :portfolio_id => portfolio.id, :tenant_id => tenant1.id) }
  let(:portfolio_item_id) { portfolio_item.id }

  it_behaves_like "aceable"

  context "length restrictions" do
    it "raises validation error" do
      expect do
        Portfolio.create!(:name => 'a'*65, :tenant => tenant1, :description => 'abc', :owner => 'fred')
      end.to raise_error(ActiveRecord::RecordInvalid, /Name is too long/)
    end
  end

  context "when setting portfolio fields" do
    it "fails validation with a non %w(true false) value" do
      portfolio.enabled = "tralse"
      expect(portfolio).to_not be_valid
    end
  end

  context "destroy portfolio cascading portfolio_items" do
    it "destroys portfolio_items only associated with the current portfolio" do
      portfolio.add_portfolio_item(portfolio_item)
      portfolio.destroy
      expect(Portfolio.find_by(:id => portfolio_id)).to be_nil
      expect(PortfolioItem.find_by(:id => portfolio_item_id)).to be_nil
    end
  end

  context "when a tenant tries to create portfolios with the same name" do
    let(:portfolio_copy) { create(:portfolio, :tenant_id => tenant1.id) }

    it "will fail validation" do
      portfolio.update(:name => "samename")
      portfolio_copy.update(:name => "samename")

      expect(portfolio).to be_valid
      expect(portfolio_copy).to_not be_valid
      expect(portfolio_copy.errors.messages[:name]).to_not be_nil

      expect { portfolio_copy.save! }.to raise_exception(ActiveRecord::RecordInvalid)
    end
  end

  context "when different tenants try to create portfolios with the same name" do
    let(:portfolio_copy) { create(:portfolio, :tenant_id => tenant2.id) }

    it "will pass validation" do
      portfolio.update(:name => "samename")
      portfolio_copy.update(:name => "samename")

      expect(portfolio).to be_valid
      expect(portfolio_copy).to be_valid

      expect { portfolio_copy.save! }.to_not raise_error
    end
  end

  context "with current_tenant" do
    let(:portfolio_two) { create(:portfolio, :tenant_id => tenant2.id) }

    describe "#add_portfolio_item" do
      it "only finds a portfolio scoped to the current_tenant" do
        portfolio
        portfolio_two

        ActsAsTenant.without_tenant do
          expect(Portfolio.all.count).to eq 2
        end

        ActsAsTenant.with_tenant(tenant1) do
          expect(Portfolio.all.count).to eq 1
          expect(Portfolio.first.tenant_id).to eq tenant1.id
        end

        ActsAsTenant.with_tenant(tenant2) do
          expect(Portfolio.all.count).to eq 1
          expect(Portfolio.first.tenant_id).to eq tenant2.id
        end
      end
    end
  end

  context "default socpe" do
    it "returns portfolios sorted by case insensitive names" do
      Portfolio.destroy_all
      %w[aa bb Bc Ad].each { |name| create(:portfolio, :name => name) }

      expect(Portfolio.pluck(:name)).to eq(%w[aa Ad bb Bc])
    end
  end

  context ".policy_class" do
    it "is PortfolioPolicy" do
      expect(Portfolio.policy_class).to eq(PortfolioPolicy)
    end
  end
end
