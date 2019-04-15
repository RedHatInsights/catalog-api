describe Portfolio do
  let(:tenant1)           { create(:tenant) }
  let(:tenant2)           { create(:tenant) }
  let(:portfolio)         { create(:portfolio, :tenant_id => tenant1.id) }
  let(:portfolio_id)      { portfolio.id }
  let(:portfolio_item)    { create(:portfolio_item, :tenant_id => tenant1.id) }
  let(:portfolio_item_id) { portfolio_item.id }

  context "when setting portfolio fields" do
    it "fails validation with a bad uri" do
      portfolio.image_url = "notreallyaurl"
      expect(portfolio).to_not be_valid
    end

    it "fails validation with a non %w(true false) value" do
      portfolio.enabled = "tralse"
      expect(portfolio).to_not be_valid
    end
  end

  context "destroy portfolio cascading portfolio_items" do
    it "destroys portfolio_items only associated with the current portfolio" do
      portfolio.add_portfolio_item(portfolio_item)
      portfolio.destroy
      expect(Portfolio.find_by(:id => portfolio_id)).to be_nil
      expect(PortfolioItem.find_by(:id => portfolio_item_id)).to be_nil
    end
  end

  context "when updating a portfolio" do
    let(:workflow_ref) { Time.now.to_i }

    it "will allow adding a workflow_ref" do
      expect(portfolio.update(:workflow_ref => workflow_ref)).to be_truthy
      expect(portfolio.workflow_ref).to eq workflow_ref.to_s
    end
  end

  context "when a tenant tries to create portfolios with the same name" do
    let(:portfolio_copy) { create(:portfolio, :tenant_id => tenant1.id) }

    it "will fail validation" do
      portfolio.update(:name => "samename")
      portfolio_copy.update(:name => "samename")

      expect(portfolio).to be_valid
      expect(portfolio_copy).to_not be_valid
      expect(portfolio_copy.errors.messages[:name]).to_not be_nil

      expect { portfolio_copy.save! }.to raise_exception(ActiveRecord::RecordInvalid)
    end
  end

  context "when different tenants try to create portfolios with the same name" do
    let(:portfolio_copy) { create(:portfolio, :tenant_id => tenant2.id) }

    it "will pass validation" do
      portfolio.update(:name => "samename")
      portfolio_copy.update(:name => "samename")

      expect(portfolio).to be_valid
      expect(portfolio_copy).to be_valid

      expect { portfolio_copy.save! }.to_not raise_error
    end
  end

  context "with current_tenant" do
    let(:portfolio_two) { create(:portfolio, :tenant_id => tenant2.id) }

    describe "#add_portfolio_item" do
      it "only finds a portfolio scoped to the current_tenant" do
        portfolio
        portfolio_two

        ActsAsTenant.without_tenant do
          expect(Portfolio.all.count).to eq 2
        end

        ActsAsTenant.with_tenant(tenant1) do
          expect(Portfolio.all.count).to eq 1
          expect(Portfolio.first.tenant_id).to eq tenant1.id
        end

        ActsAsTenant.with_tenant(tenant2) do
          expect(Portfolio.all.count).to eq 1
          expect(Portfolio.first.tenant_id).to eq tenant2.id
        end
      end
    end
  end
end
