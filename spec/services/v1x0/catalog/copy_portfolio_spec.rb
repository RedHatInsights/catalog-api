describe V1x0::Catalog::CopyPortfolio, :type => :service do
  let(:portfolio) { create(:portfolio, :icon => create(:icon)) }
  let!(:portfolio_item1) { create(:portfolio_item, :portfolio => portfolio) }
  let!(:portfolio_item2) { create(:portfolio_item, :portfolio => portfolio) }

  let(:copy_portfolio) { described_class.new(:portfolio_id => portfolio.id).process }

  describe "#process" do
    let(:new_portfolio) { copy_portfolio.new_portfolio }

    context "when there isn't a conflicting name" do
      it "copies the portfolio over" do
        expect(new_portfolio.owner).to eq portfolio.owner
        expect(new_portfolio.description).to eq portfolio.description
      end

      it "modifies the name" do
        expect(new_portfolio.name).to match(/^Copy of.*/)
      end

      it "copies over the icon" do
        new = copy_portfolio.new_portfolio

        expect(new.icon_id).not_to eq portfolio.icon_id
        expect(new.icon.image_id).to eq portfolio.icon.image_id
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

    context "copy when there is a copy already" do
      let!(:another_portfolio) { create(:portfolio, :name => "Copy of #{portfolio.name}") }

      it "adds a (1) to the name" do
        expect(new_portfolio.name).to eq "Copy (1) of #{portfolio.name}"
      end

      it "increments when requesting again" do
        another_portfolio.update(:name => "Copy (1) of #{portfolio.name}")
        expect(new_portfolio.name).to eq "Copy (2) of #{portfolio.name}"
      end
    end
  end
end
