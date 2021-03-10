describe Api::V1x0::Catalog::CopyPortfolio, :type => :service do
  let(:portfolio) { create(:portfolio, :icon => create(:icon)) }
  let!(:portfolio_item1) { create(:portfolio_item, :portfolio => portfolio) }
  let!(:portfolio_item2) { create(:portfolio_item, :portfolio => portfolio) }
  let(:portfolio_item_orderable) { instance_double(Api::V1x1::Catalog::PortfolioItemOrderable, :result => true) }

  let(:copy_portfolio) { described_class.new(:portfolio_id => portfolio.id).process }

  describe "#process" do
    let(:new_portfolio) { copy_portfolio.new_portfolio }

    before do
      allow(Api::V1x1::Catalog::PortfolioItemOrderable).to receive(:new).and_return(portfolio_item_orderable)
      allow(portfolio_item_orderable).to receive(:process).and_return(portfolio_item_orderable)
    end

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
        expect(new.icon.restore_to).to eq new_portfolio
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

    context "with exception during copy" do
      let(:copy_portfolio) { described_class.new(:portfolio_id => portfolio.id) }
      let(:error)          { ::Catalog::OrderUncancelable }

      before do
        allow(copy_portfolio).to receive(:copy_portfolio_items).and_raise(error)
        expect { copy_portfolio.process }.to raise_error(error)
      end

      it 'does not create a new portfolio' do
        expect(copy_portfolio.new_portfolio).to eq(nil)
      end

      it 'removes all partial data' do
        expect(Icon.count).to eq(1)
        expect(Portfolio.count).to eq(2)
        expect(PortfolioItem.count).to eq(3)
      end
    end
  end
end
