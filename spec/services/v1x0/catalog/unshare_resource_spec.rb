describe V1x0::Catalog::UnshareResource, :type => :service do
  let(:portfolio) { create(:portfolio) }
  let(:uuid) { "123" }

  let(:params) do
    {
      :group_uuids => [uuid],
      :permissions => %w[read update],
      :object      => portfolio
    }
  end
  let(:group_validator) { instance_double(Insights::API::Common::RBAC::ValidateGroups) }

  before do
    create(:access_control_entry, :has_read_permission, :group_uuid => uuid, :aceable => portfolio)
    create(:access_control_entry, :has_update_permission, :group_uuid => uuid, :aceable => portfolio)
    allow(Insights::API::Common::RBAC::ValidateGroups).to receive(:new).with([uuid]).and_return(group_validator)
    allow(group_validator).to receive(:process)
  end

  let(:subject) { described_class.new(params) }

  describe "#process" do
    it "validates the groups" do
      expect(group_validator).to receive(:process)
      subject.process
    end

    it "removes the access control entries on the portfolio" do
      expect(portfolio.access_control_entries.count).to eq(2)
      subject.process
      portfolio.reload
      expect(portfolio.access_control_entries.count).to eq(0)
    end
  end
end
