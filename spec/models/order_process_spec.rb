describe OrderProcess do
  let(:tenant1) { create(:tenant, :external_tenant => "1") }
  let(:tenant2) { create(:tenant, :external_tenant => "2") }
  let(:order_process1) { create(:order_process, :tenant => tenant1) }

  it { is_expected.to have_many(:tag_links) }

  it ".taggable?" do
    expect(OrderProcess.taggable?).to be_truthy
  end

  context "with tenants" do
    before do
      create(:order_process, :tenant => tenant1)
      create(:order_process, :tenant => tenant2)
    end

    it "only returns order_process with current tenant" do
      ActsAsTenant.without_tenant do
        expect(OrderProcess.count).to eq(2)
      end

      ActsAsTenant.with_tenant(tenant1) do
        expect(OrderProcess.count).to eq(1)
        expect(OrderProcess.first.tenant_id).to eq(tenant1.id)
      end
    end
  end

  context "name validation" do
    context "when no name is given" do
      before do
        order_process1.update(:name => nil)
      end

      it "fails validation" do
        expect(order_process1).to_not be_valid
        expect(order_process1.errors.messages[:name]).to eq(["can't be blank"])
      end
    end

    context "when there is a duplicate name" do
      let(:order_process1_copy) { create(:order_process, :tenant_id => tenant_id) }

      before do
        order_process1.update(:name => "dup")
        order_process1_copy.update(:name => "dup")
      end

      context "when the tenant is the same" do
        let(:tenant_id) { tenant1.id }

        it "fails validation" do
          expect(order_process1).to be_valid
          expect(order_process1_copy).to_not be_valid
          expect(order_process1_copy.errors.messages[:name]).to eq(["has already been taken"])
        end
      end

      context "when the tenant is different" do
        let(:tenant_id) { tenant2.id }

        it "passes validation" do
          expect(order_process1).to be_valid
          expect(order_process1_copy).to be_valid
        end
      end
    end
  end

  describe '#move_internal_sequence' do
    around(:each) do |example|
      ActsAsTenant.with_tenant(tenant2) { example.run }
    end

    let(:old_ids) do
      create_list(:order_process, 5)
      OrderProcess.pluck(:id)
    end

    it 'moves up sequence in range' do
      OrderProcess.find(old_ids[4]).move_internal_sequence(-2)
      expect(OrderProcess.pluck(:id)).to eq([old_ids[0], old_ids[1], old_ids[4], old_ids[2], old_ids[3]])
    end

    it 'moves down sequence in range' do
      OrderProcess.find(old_ids[1]).move_internal_sequence(2)
      expect(OrderProcess.pluck(:id)).to eq([old_ids[0], old_ids[2], old_ids[3], old_ids[1], old_ids[4]])
    end

    it 'moves up to top' do
      OrderProcess.find(old_ids[2]).move_internal_sequence(-2)
      expect(OrderProcess.pluck(:id)).to eq([old_ids[2], old_ids[0], old_ids[1], old_ids[3], old_ids[4]])
    end

    it 'moves down to bottom' do
      OrderProcess.find(old_ids[3]).move_internal_sequence(1)
      expect(OrderProcess.pluck(:id)).to eq([old_ids[0], old_ids[1], old_ids[2], old_ids[4], old_ids[3]])
    end

    it 'moves up beyond range' do
      OrderProcess.find(old_ids[2]).move_internal_sequence(-20)
      expect(OrderProcess.pluck(:id)).to eq([old_ids[2], old_ids[0], old_ids[1], old_ids[3], old_ids[4]])
    end

    it 'moves down beyond range' do
      OrderProcess.find(old_ids[3]).move_internal_sequence(20)
      expect(OrderProcess.pluck(:id)).to eq([old_ids[0], old_ids[1], old_ids[2], old_ids[4], old_ids[3]])
    end

    it 'moves up to top explicitly' do
      OrderProcess.find(old_ids[2]).move_internal_sequence(-Float::INFINITY)
      expect(OrderProcess.pluck(:id)).to eq([old_ids[2], old_ids[0], old_ids[1], old_ids[3], old_ids[4]])
    end

    it 'moves down to bottom explicitly' do
      OrderProcess.find(old_ids[3]).move_internal_sequence(Float::INFINITY)
      expect(OrderProcess.pluck(:id)).to eq([old_ids[0], old_ids[1], old_ids[2], old_ids[4], old_ids[3]])
    end

    it 'places the newly created workflow to the end of list' do
      old_ids
      nw = OrderProcess.create(:name => 'new order process')
      expect(OrderProcess.pluck(:id)).to eq([old_ids[0], old_ids[1], old_ids[2], old_ids[3], old_ids[4], nw.id])
    end

    it 'maintains sorting after one workflow is removed' do
      OrderProcess.find(old_ids[3]).destroy
      expect(OrderProcess.pluck(:id)).to eq([old_ids[0], old_ids[1], old_ids[2], old_ids[4]])
    end
  end

  describe '#positive_internal_sequence' do
    it 'validates the internal_sequence must be positive' do
      expect { order_process1.update!(:internal_sequence => -1) }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Internal sequence must be positive')
    end
  end
end
