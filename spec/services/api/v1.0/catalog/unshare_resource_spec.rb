describe Api::V1x0::Catalog::UnshareResource, :type => :service do
  let(:portfolio) { create(:portfolio) }
  let(:uuid) { "123" }
  let(:group_validator) { instance_double(Insights::API::Common::RBAC::ValidateGroups) }

  before do
    create(:access_control_entry, :has_read_and_update_permission, :group_uuid => uuid, :aceable => portfolio)
    create(:access_control_entry, :has_read_and_update_permission, :group_uuid => "456", :aceable => portfolio)
    allow(Insights::API::Common::RBAC::ValidateGroups).to receive(:new).with([uuid]).and_return(group_validator)
    allow(group_validator).to receive(:process)
  end

  let(:subject) { described_class.new(params) }

  describe "#process" do
    context "when the permissions include all permissions available" do
      let(:params) do
        {
          :group_uuids => [uuid],
          :permissions => %w[read update order],
          :object      => portfolio
        }
      end

      it "validates the groups" do
        expect(group_validator).to receive(:process)
        subject.process
      end

      it "removes the permissions" do
        expect(portfolio.access_control_entries.first.permissions.count).to eq(2)
        subject.process
        portfolio.reload
        expect(portfolio.access_control_entries.first.permissions.count).to eq(0)
      end

      it "does not remove permissions from other access control entries" do
        expect(portfolio.access_control_entries.last.permissions.collect(&:name)).to match_array(%w[read update])
        subject.process
        portfolio.reload
        expect(portfolio.access_control_entries.last.permissions.collect(&:name)).to match_array(%w[read update])
      end
    end

    context "when permissions are only 1 of the existing permissions" do
      let(:params) do
        {
          :group_uuids => [uuid],
          :permissions => %w[read],
          :object      => portfolio
        }
      end

      it "validates the groups" do
        expect(group_validator).to receive(:process)
        subject.process
      end

      it "removes the read permission" do
        expect(portfolio.access_control_entries.first.permissions.collect(&:name)).to match_array(%w[read update])
        subject.process
        portfolio.reload
        expect(portfolio.access_control_entries.first.permissions.collect(&:name)).to match_array(%w[update])
      end

      it "does not remove permissions from other access control entries" do
        expect(portfolio.access_control_entries.last.permissions.collect(&:name)).to match_array(%w[read update])
        subject.process
        portfolio.reload
        expect(portfolio.access_control_entries.last.permissions.collect(&:name)).to match_array(%w[read update])
      end
    end
  end
end
