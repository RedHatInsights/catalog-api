describe Catalog::CopyPortfolioItem do
  let(:tenant) { create(:tenant) }
  let(:portfolio) { create(:portfolio, :tenant_id => tenant.id) }
  let(:portfolio2) { create(:portfolio, :tenant_id => tenant.id) }
  let(:portfolio_item) { create(:portfolio_item, :portfolio_id => portfolio.id, :tenant_id => tenant.id) }

  let(:copy_portfolio_item) { described_class.new(params).process }

  describe "#process" do
    context "when copying into the same portfolio" do
      around do |example|
        bypass_rbac { example.call }
      end

      let(:params) { { :portfolio_item_id => portfolio_item.id, :portfolio_id => portfolio.id } }

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
      around do |example|
        bypass_rbac { example.call }
      end

      let(:params) { { :portfolio_item_id => portfolio_item.id, :portfolio_id => portfolio2.id } }

      it "makes a complete copy of the portfolio_item" do
        new = copy_portfolio_item.new_portfolio_item

        expect(new.description).to eq portfolio_item.description
        expect(new.owner).to eq portfolio_item.owner
        expect(copy_portfolio_item.new_portfolio_item.name).to eq portfolio_item.name
      end
    end
  end

  describe "#get_index" do
    let(:params) { { :portfolio_item_id => portfolio_item.id, :portfolio_id => portfolio2.id } }

    it "gets the index for the names" do
      names = ["Copy of #{portfolio_item.name}",
               portfolio_item.name.to_s,
               "Copy (2) of #{portfolio_item.name}",
               "Copy (1) of #{portfolio_item.name}"]
      index = copy_portfolio_item.send(:get_index, names)
      expect(index).to eq 2
    end

    it "returns 0 if there isn't more than one copy yet" do
      names = ["Copy of #{portfolio_item.name}", portfolio_item.name.to_s]
      index = copy_portfolio_item.send(:get_index, names)
      expect(index).to eq 0
    end
  end
end
