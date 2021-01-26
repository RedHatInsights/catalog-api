describe Api::V1x0::Catalog::CopyPortfolioItem, :type => :service do
  let(:portfolio) { create(:portfolio) }
  let(:portfolio2) { create(:portfolio) }
  let(:portfolio_item) { create(:portfolio_item, :portfolio => portfolio, :icon => create(:icon)) }

  let(:copy_portfolio_item) { described_class.new(params).process }

  describe "#process" do
    context "when copying into the same portfolio" do
      let(:params) { { :portfolio_item_id => portfolio_item.id, :portfolio_id => portfolio.id } }

      it "makes a copy of the portfolio_item" do
        copied_portfolio = copy_portfolio_item.new_portfolio_item

        expect(copied_portfolio.description).to eq portfolio_item.description
        expect(copied_portfolio.owner).to eq portfolio_item.owner
      end

      it "modifies the name with 'Copy of'" do
        expect(copy_portfolio_item.new_portfolio_item.name).to match(/^Copy of.*/)
      end
    end

    context "when copying into a different portfolio" do
      let(:params) { { :portfolio_item_id => portfolio_item.id, :portfolio_id => portfolio2.id } }
      let(:copied_portfolio) { copy_portfolio_item.new_portfolio_item }

      it "makes a complete copy of the portfolio_item" do
        expect(copied_portfolio.description).to eq portfolio_item.description
        expect(copied_portfolio.owner).to eq portfolio_item.owner
      end

      it "does not modify the name with 'Copy of'" do
        expect(copied_portfolio.name).to eq portfolio_item.name
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
        copied_portfolio = copy_portfolio_item.new_portfolio_item
        expect(copied_portfolio.name).to eq "Copy (1) of #{portfolio_item.name}"
      end

      it "increments the counter again when adding another" do
        another_portfolio_item.update(:name => "Copy (1) of #{portfolio_item.name}")
        copied_portfolio = copy_portfolio_item.new_portfolio_item
        expect(copied_portfolio.name).to eq "Copy (2) of #{portfolio_item.name}"
      end
    end

    context "when the portfolio_item has an icon" do
      let(:params) { { :portfolio_item_id => portfolio_item.id, :portfolio_id => portfolio.id } }

      it "copies over the icon" do
        copied_portfolio_item = copy_portfolio_item.new_portfolio_item

        expect(copied_portfolio_item.icon_id).not_to eq portfolio_item.icon_id
        expect(copied_portfolio_item.icon.image_id).to eq portfolio_item.icon.image_id
        expect(copied_portfolio_item.icon.restore_to).to eq copied_portfolio_item
      end
    end

    context "when the portfolio_item has service_plans" do
      context "when the service_plan base match inventory" do
        let(:params) { { :portfolio_item_id => portfolio_item.id, :portfolio_id => portfolio.id } }

        before do
          allow(Catalog::SurveyCompare).to receive(:changed?).and_return(false)
          allow(Catalog::DataDrivenFormValidator).to receive(:valid?).and_return(true)

          portfolio_item.service_plans.create!(
            :base     => {"schema" => {}},
            :modified => {"schema" => {}}
          )
        end

        it "copies over the service_plan" do
          copied_portfolio_item = copy_portfolio_item.new_portfolio_item

          expect(copied_portfolio_item.service_plans).not_to match_array portfolio_item.service_plans
          expect(copied_portfolio_item.service_plans.first.base).to eq portfolio_item.service_plans.first.base
        end
      end

      context "when the service_plan base do not match inventory" do
        let(:params) { { :portfolio_item_id => portfolio_item.id, :portfolio_id => portfolio.id } }

        before do
          allow(Catalog::SurveyCompare).to receive(:changed?).and_return(true)

          portfolio_item.service_plans.create!(
            :base     => {"schema" => {}},
            :modified => {"schema" => {}}
          )
        end

        it "fails the copy" do
          expect { copy_portfolio_item }.to raise_exception(Catalog::InvalidSurvey)
          expect(PortfolioItem.pluck(:name).select { |name| name.match?(/#{portfolio_item.name}/) }.count).to eq 1
        end
      end
    end
  end
end
