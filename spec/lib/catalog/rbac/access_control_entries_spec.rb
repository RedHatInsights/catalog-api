describe Catalog::RBAC::AccessControlEntries do
  describe "#ace_ids" do
    subject { described_class.new(["123-456"]) }

    context "when access control entries exist that match the given parameters" do
      before do
        create(:access_control_entry, :has_read_permission, :aceable_id => "123")
        create(:access_control_entry, :has_read_permission, :aceable_id => "456")
        create(:access_control_entry, :has_read_permission, :aceable_id => "789", :group_uuid => "123-4567")
      end

      it "returns a list of the permitted object ids" do
        expect(subject.ace_ids('read', Portfolio)).to match_array(["123", "456"])
      end
    end

    context "when access control entries do not exist that match the given parameters" do
      before do
        create(:access_control_entry, :has_update_permission, :aceable_id => "123")
        create(:access_control_entry, :has_read_permission, :aceable_id => "789", :group_uuid => "456-123")
      end

      it "returns an empty list" do
        expect(subject.ace_ids('read', Portfolio)).to eq([])
      end
    end
  end
end
