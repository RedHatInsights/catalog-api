describe PortfolioItem do
  let(:item) { build(:portfolio_item) }

  let(:service_offering_ref) { "1" }
  let(:owner) { 'wilma' }

  context "requires a service_offering_ref" do
    before do
      item.owner = owner
    end

    it "is not valid without a service_offering_ref" do
      item.service_offering_ref = nil
      expect(item).to_not be_valid
    end

    it "is valid when we set a service_offering_ref" do
      item.service_offering_ref = service_offering_ref
      expect(item).to be_valid
    end
  end

  context "requires an owner" do
    before do
      item.service_offering_ref = service_offering_ref
    end

    it "is not valid without an owner" do
      item.owner = nil
      expect(item).to_not be_valid
    end

    it "is valid when we set an owner" do
      item.owner = owner
      expect(item).to be_valid
    end
  end

  context "default socpe" do
    it "returns portfolio_items sorted by case insensitive names" do
      %w[ab bb Bc Ad].each { |name| create(:portfolio_item, :name => name) }

      expect(PortfolioItem.pluck(:name)).to eq(%w[ab Ad bb Bc])
    end
  end

  context ".policy_class" do
    it "is PortfolioItemPolicy" do
      expect(PortfolioItem.policy_class).to eq(PortfolioItemPolicy)
    end
  end

  context "length restrictions" do
    it "raises validation error" do
      expect do
        PortfolioItem.create!(:name => 'a' * 513, :description => 'abc', :owner => 'fred')
      end.to raise_error(ActiveRecord::RecordInvalid, /Name is too long/)
    end
  end

  context "callbacks" do
    let(:portfolio) { build(:portfolio) }
    subject! { create(:portfolio_item, :portfolio => portfolio) }

    %i[create destroy discard undiscard].each do |kind|
      it "calls update_portfolio_stats on #{kind}" do
        expect(portfolio).to receive(:update_metadata)

        subject.run_callbacks kind
      end
    end

    it "runs validate_deletable callback" do
      expect(subject).to receive(:validate_deletable)

      subject.run_callbacks 'discard'
    end
  end

  describe "#validate_deletable" do
    let(:portfolio) { create(:portfolio) }
    subject! { create(:portfolio_item, :portfolio => portfolio) }

    it "passes validation when there is no order process associated" do
      expect(subject.validate_deletable).to be_nil
    end

    context "when is the before/after portfolio item of an order process" do
      let!(:order_process1) { create(:order_process, :name => "foo", :before_portfolio_item_id => subject.id) }
      let!(:order_process2) { create(:order_process, :name => "bar", :after_portfolio_item_id => subject.id) }

      it "raises an error" do
        expect { subject.validate_deletable }.to raise_error(UncaughtThrowError, "uncaught throw :abort")
        expect(subject.errors[:base]).to include("cannot be deleted because it is used by order processes #{OrderProcess.pluck(:name)}")
      end
    end
  end

  context "with two valid tags" do
    let(:portfolio) { create(:portfolio) }
    subject! { create(:portfolio_item, :portfolio => portfolio) }

    before do
      subject.tag_add('workflows', :namespace => 'approval', :value => '123')
      subject.tag_add('workflows', :namespace => 'approval', :value => '456')
      subject.tag_add('order_processes', :namespace => 'approval', :value => '789')
    end

    it 'adds staticsitcs' do
      expect(subject.metadata.keys).to match_array(%w[statistics updated_at user_capabilities])
    end

    it 'returns statistics with approval_processes value of two' do
      expect(subject.metadata['statistics']['approval_processes']).to eq(2)
    end
  end
end
