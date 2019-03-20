describe Catalog::HierarchicalModelSearch do
  let!(:portfolio) { create(:portfolio) }
  let!(:portfolio_item) { create(:portfolio_item) }
  let(:portfolio_item_id) { portfolio_item.id }

  let(:hierarchy) { %w[PortfolioItem Portfolio] }
  let(:search_for) { "workflow_ref" }

  let(:hierarchy_search) { described_class.new(search_for, portfolio_item_id, hierarchy) }

  before do
    portfolio.portfolio_items << portfolio_item
  end

  context "when the first item has the field to search for" do
    let(:ref_text) { "first_item_workflow_ref" }

    before do
      portfolio_item.update(:workflow_ref => ref_text)
    end

    it "finds the field on the first item" do
      expect(hierarchy_search.process.field).to eq ref_text
    end
  end

  context "when the first item is missing the field" do
    let(:ref_text) { "second_item_workflow_ref" }

    before do
      portfolio.update(:workflow_ref => ref_text)
    end

    it "fails to find the text on the first item, so it looks at the second one." do
      expect(hierarchy_search.process.field).to eq ref_text
    end
  end

  context "when the hierarchy passed in is missing a key reference to the next object" do
    let(:bad_hierarchy) { %w[Portfolio PortfolioItem] }

    it "throws an exception when trying to access the _id field" do
      hierarchy_inst = described_class.new(search_for, portfolio_item_id, bad_hierarchy)
      expect { hierarchy_inst.process }.to raise_exception(RuntimeError)
    end
  end
end
