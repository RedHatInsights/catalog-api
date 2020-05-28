describe TenantPolicy do
  let(:user_context) { instance_double(UserContext, :group_uuids => ["123-456"]) }
  let(:tenant) { create(:tenant) }
  let(:subject) { described_class.new(user_context, tenant) }
  let(:rbac_access) { instance_double(Catalog::RBAC::Access) }

  before do
    allow(Catalog::RBAC::Access).to receive(:new).with(user_context, tenant).and_return(rbac_access)
  end

  it "#show?" do
    expect(rbac_access).to receive(:permission_check).with('read').and_return(true)
    expect(subject.show?).to be_truthy
  end

  it "#update?" do
    expect(rbac_access).to receive(:permission_check).with('update').and_return(true)
    expect(subject.update?).to be_truthy
  end
end
