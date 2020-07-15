RSpec.describe TagLink, :type => :model do
  let(:order_process) { create(:order_process) }
  let(:a_tag) { {:order_process => order_process, :object_type => 'inventory', :app_name => 'catalog', :tag_name => '/catalog/order_processes/abc'} }

  it { is_expected.to belong_to(:order_process) }

  context 'duplicated tag link in different tenants' do
    let(:tenant1) { create(:tenant, :external_tenant => "1234") }
    let(:tenant2) { create(:tenant, :external_tenant => "2345") }

    before { ActsAsTenant.with_tenant(tenant1) { described_class.create(a_tag) } }

    it 'counts the same link in another tenant' do
      expect(described_class.count).to eq(1)

      ActsAsTenant.with_tenant(tenant2) do
        expect(described_class.count).to eq(0)
      end
    end
  end

  context 'duplicated tag link in the same tenant' do
    let(:tenant) { create(:tenant) }

    before { ActsAsTenant.with_tenant(tenant) { described_class.create(a_tag) } }

    it 'raises an error while attempting to create the same link' do
      ActsAsTenant.with_tenant(tenant) do
        expect { described_class.create!(a_tag) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
