RSpec.describe AccessControlEntry, :type => :model do
  it { is_expected.to have_db_column(:aceable_id).of_type(:integer) }
  it { is_expected.to have_db_column(:aceable_type).of_type(:string) }

  it { is_expected.to belong_to(:aceable) }

  context "Permissions" do
    let(:ace) { create(:access_control_entry, :has_read_permission) }
    describe "add_new_permissions" do
      it "only adds new" do
        new_perm = ["delete"]
        expect(ace.permissions.map(&:name)).to eq ["read"]
        ace.add_new_permissions(new_perm)
        expect(ace.permissions.map(&:name)).to eq ["read", "delete"]
      end

      it "does not add existing" do
        new_perm = ["read"]
        expect(ace.permissions.map(&:name)).to eq ["read"]
        ace.add_new_permissions(new_perm)
        expect(ace.permissions.map(&:name)).to eq ["read"]
      end
    end
  end
end
