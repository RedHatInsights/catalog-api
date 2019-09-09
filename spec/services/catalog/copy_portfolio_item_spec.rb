describe Catalog::CopyPortfolioItem, :type => :service do
  let(:portfolio) { create(:portfolio) }
  let(:portfolio2) { create(:portfolio) }
  let(:portfolio_item) { create(:portfolio_item, :portfolio => portfolio) }

  let(:copy_portfolio_item) { described_class.new(params).process }

  describe "#process" do
    context "when copying into the same portfolio" do
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
      let(:params) { { :portfolio_item_id => portfolio_item.id, :portfolio_id => portfolio2.id } }
      let(:new) { copy_portfolio_item.new_portfolio_item }

      it "makes a complete copy of the portfolio_item" do
        expect(new.description).to eq portfolio_item.description
        expect(new.owner).to eq portfolio_item.owner
      end

      it "does not modify the name with 'Copy of'" do
        expect(new.name).to eq portfolio_item.name
      end
    end

    context "when making multiple copies" do
      let(:params) { { :portfolio_item_id => portfolio_item.id, :portfolio_id => portfolio.id } }
      let!(:another_portfolio_item) do
        create(:portfolio_item,
               :portfolio => portfolio,
               :name      => "Copy of #{portfolio_item.name}")
      end

      it "adds a (1) to the name if there is already a copy" do
        new = copy_portfolio_item.new_portfolio_item
        expect(new.name).to eq "Copy (1) of #{portfolio_item.name}"
      end

      it "increments the counter again when adding another" do
        another_portfolio_item.update(:name => "Copy (1) of #{portfolio_item.name}")
        new = copy_portfolio_item.new_portfolio_item
        expect(new.name).to eq "Copy (2) of #{portfolio_item.name}"
      end
    end
  end
end
