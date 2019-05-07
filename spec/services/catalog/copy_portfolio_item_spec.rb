describe Catalog::CopyPortfolioItem do
  let(:tenant) { create(:tenant) }
  let(:portfolio_item) { create(:portfolio_item, :portfolio_id => "1", :tenant_id => 1) }

  let(:copy_portfolio_item) { described_class.new(params).process }

  describe "#process" do
    context "when copying into the same portfolio" do
      let(:params) { { :portfolio_item_id => portfolio_item.id, :portfolio_id => "1" } }

      it "makes a copy of the portfolio_item" do
        new = copy_portfolio_item.new_portfolio_item

        expect(new.description).to eq portfolio_item.description
        expect(new.owner).to eq portfolio_item.owner
      end

      it "modifies the name with 'Copy of'" do
        expect(copy_portfolio_item.new_portfolio_item.name).to match(/^Copy of.*/)
      end
    end

    context "when copying into a different portfolio" do
      let(:params) { { :portfolio_item_id => portfolio_item.id, :portfolio_id => "2" } }

      it "makes a complete copy of the portfolio_item" do
        new = copy_portfolio_item.new_portfolio_item

        expect(new.description).to eq portfolio_item.description
        expect(new.owner).to eq portfolio_item.owner
        expect(copy_portfolio_item.new_portfolio_item.name).to eq portfolio_item.name
      end
    end
  end
end
