describe Portfolio do
  let(:portfolio)       { FactoryBot.create(:portfolio) }
  let(:portfolio_item)  { FactoryBot.create(:portfolio_item) }

  context "#add_portfolio_item" do
    it "returns the last added portfolio_item" do
      expect(portfolio.add_portfolio_item(portfolio_item.id).first).to be_a PortfolioItem
    end

    it "adds the portfolio_item passed into the method" do
      expect(portfolio.add_portfolio_item(portfolio_item.id).first.id).to eq portfolio_item.id
    end
  end
end
