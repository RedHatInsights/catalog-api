require "models/concerns/aceable_shared"
describe Portfolio do
  let(:tenant1)           { create(:tenant, :external_tenant => "1") }
  let(:tenant2)           { create(:tenant, :external_tenant => "2") }
  let(:portfolio)         { create(:portfolio, :tenant => tenant1) }
  let(:portfolio_id)      { portfolio.id }
  let!(:portfolio_item)   { create(:portfolio_item, :portfolio => portfolio, :tenant => tenant1) }
  let(:portfolio_item_id) { portfolio_item.id }

  it_behaves_like "aceable"

  context "length restrictions" do
    it "raises validation error" do
      expect do
        Portfolio.create!(:name => 'a'*513, :tenant => tenant1, :description => 'abc', :owner => 'fred')
      end.to raise_error(ActiveRecord::RecordInvalid, /Name is too long/)
    end
  end

  context "when setting portfolio fields" do
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

  context "default socpe" do
    it "returns portfolios sorted by case insensitive names" do
      Portfolio.destroy_all
      %w[aa bb Bc Ad].each { |name| create(:portfolio, :name => name) }

      expect(Portfolio.pluck(:name)).to eq(%w[aa Ad bb Bc])
    end
  end

  context ".policy_class" do
    it "is PortfolioPolicy" do
      expect(Portfolio.policy_class).to eq(PortfolioPolicy)
    end
  end

  context "tags" do
    let(:options) { { :namespace => 'test', :value => '1' } }
    let(:name) { 'fred' }
    before do
      portfolio.tag_add(name, options)
    end

    it "#tag_list" do
      expect(portfolio.tag_list).to match_array([name])
    end

    it "#taggings" do
      expect(portfolio.taggings.first).to include(:name => name)
    end

    it "#tag_remove" do
      portfolio.tag_remove(name, options)
      expect(portfolio.tag_list).to be_empty
    end

    it ".tagged_with" do
      expect(Portfolio.tagged_with(name, options).first.id). to eq(portfolio.id)
    end

    it ".taggable?" do
      expect(Portfolio.taggable?).to be_truthy
    end
  end

  context 'callbacks' do
    before { subject.run_callbacks :create }

    it 'adds limited keys to metadata' do
      expect(subject.metadata.keys).to_not include(AncillaryMetadata::NON_METADATA_ATTRIBUTES)
    end

    it 'adds staticsitcs' do
      expect(subject.metadata['statistics']).to include(
        'portfolio_items'    => 0,
        'shared_groups'      => 0
      )
    end
  end

  describe '#update_metadata' do
    context 'ancillary_metadata instance does not exist' do
      it 'creates ancillary_metadata instance but does not save it' do
        expect(subject).to receive(:build_ancillary_metadata).and_call_original
        expect(subject).to receive(:update_ancillary_metadata)

        subject.update_metadata
        expect(subject.ancillary_metadata.persisted?).to be false
      end
    end

    context 'with an existing portfolio instance' do
      subject { portfolio }

      it 'updates and saves ancillary_metadata' do
        expect(subject).to receive(:update_ancillary_metadata)
        expect(subject.ancillary_metadata).to receive(:save!)

        subject.update_metadata
      end

      context 'ancillary_metadata instance was destroyed' do
        before { subject.destroy }

        it 'returns without updating ancillary_metadata' do
          expect(subject).to_not receive(:update_ancillary_metadata)

          portfolio.update_metadata
        end
      end
    end
  end

  describe '#metadata' do
    subject { create(:portfolio) }
    before { subject.run_callbacks :create }

    it 'adds staticsitcs' do
      expect(subject.metadata.keys).to match_array(%w[statistics updated_at user_capabilities])
    end

    context 'with two portfolio items' do
      before do
        2.times { create(:portfolio_item, :portfolio => subject) }
      end

      it 'returns statistics with portfolio_items value of 2' do
        expect(subject.metadata['statistics']['portfolio_items']).to be(2)
      end
    end

    context 'with an access_control_entry with permissions' do
      before do
        create(:access_control_entry, :has_read_permission, :aceable => subject)
        subject.update_metadata
      end

      it 'returns statistics with shared_groups value of 1' do
        expect(subject.metadata['statistics']['shared_groups']).to be(1)
      end
    end

    context 'with an access_control_entry without permissions' do
      before do
        create(:access_control_entry, :aceable => subject)
        subject.update_metadata
      end

      it 'returns statistics with shared_groups value of zero' do
        expect(subject.metadata['statistics']['shared_groups']).to be_zero
      end
    end
  end
end
