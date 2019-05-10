describe Catalog::CopyPortfolio do
  let(:tenant) { create(:tenant) }
  let(:portfolio) { create(:portfolio, :tenant_id => tenant.id) }
  let!(:portfolio_item1) { create(:portfolio_item, :portfolio_id => portfolio.id, :tenant_id => tenant.id) }
  let!(:portfolio_item2) { create(:portfolio_item, :portfolio_id => portfolio.id, :tenant_id => tenant.id) }

  let(:copy_portfolio) { described_class.new(:portfolio_id => portfolio.id).process }

  describe "#process" do
    let(:new_portfolio) { copy_portfolio.new_portfolio }

    it "copies the portfolio over" do
      expect(new_portfolio.owner).to eq portfolio.owner
      expect(new_portfolio.description).to eq portfolio.description
    end

    it "modifies the name" do
      expect(new_portfolio.name).to match(/^Copy of.*/)
    end

    it "copies over all of the portfolio items" do
      expect(new_portfolio.portfolio_items.count).to eq 2
    end

    it "copies over the portfolio_items fields" do
      items = new_portfolio.portfolio_items

      expect(items.collect(&:name)).to match_array([portfolio_item1.name, portfolio_item2.name])
      expect(items.collect(&:description)).to match_array([portfolio_item1.description, portfolio_item2.description])
      expect(items.collect(&:owner)).to match_array([portfolio_item1.owner, portfolio_item2.owner])
    end
  end
end
