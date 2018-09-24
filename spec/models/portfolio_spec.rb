describe Portfolio do
  let(:portfolio)      { create(:portfolio) }
  let(:portfolio_item) { create(:portfolio_item) }

  describe "#add_portfolio_item" do
    it "returns the last added portfolio_item" do
      expect(portfolio.add_portfolio_item(portfolio_item.id).first).to be_a PortfolioItem
    end

    it "adds the portfolio_item passed into the method" do
      expect(portfolio.add_portfolio_item(portfolio_item.id).first.id).to eq portfolio_item.id
    end
  end
end
