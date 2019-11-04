describe Tags::CollectLocalOrderResources do
  let(:order) { create(:order) }

  let(:order_item) { create(:order_item, :order => order) }
  let(:portfolio_item) { order_item.portfolio_item }
  let(:portfolio) { portfolio_item.portfolio }
  let(:subject) { described_class.new(:order_id => order.id.to_s) }
  let(:tag_resources) { subject.process.tag_resources }

  describe "#process" do
    context "Portfolio Item and Portfolio" do
      before do
        portfolio_item.tag_add('Gnocchi', :namespace => 'Charkie', :value => 'Hundley')
        portfolio.tag_add('Curious George', :namespace => 'Compass', :value => 'Jumpy Squirrel')
      end

      it "validates collection" do
        expect(tag_resources).to match(
          [{ :app_name    => 'catalog',
             :object_type => 'PortfolioItem',
             :tags        => [{ :name => 'Gnocchi', :namespace => 'Charkie', :value => 'Hundley' }] },
           { :app_name    => 'catalog',
             :object_type => 'Portfolio',
             :tags        => [{ :name => 'Curious George', :namespace => 'Compass', :value => 'Jumpy Squirrel' }]}]
        )
      end
    end

    context "PortfolioItem" do
      before do
        portfolio_item.tag_add('Gnocchi', :namespace => 'Charkie', :value => 'Hundley')
      end

      it "validates collection" do
        expect(tag_resources).to match(
          [{ :app_name    => 'catalog',
             :object_type => 'PortfolioItem',
             :tags        => [{ :name => 'Gnocchi', :namespace => 'Charkie', :value => 'Hundley' }] }]
        )
      end
    end

    context "no tags" do
      it "should be empty" do
        expect(tag_resources).to be_empty
      end
    end
  end
end
