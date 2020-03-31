describe Api::V1x0::Catalog::ShareResource, :type => :service do
  let(:portfolio) { create(:portfolio) }

  let(:params) do
    {
      :group_uuids => ["123"],
      :permissions => %w[read update],
      :object      => portfolio
    }
  end
  let(:group_validator) { instance_double(Insights::API::Common::RBAC::ValidateGroups) }

  let(:subject) { described_class.new(params) }

  before do
    allow(Insights::API::Common::RBAC::ValidateGroups).to receive(:new).with(["123"]).and_return(group_validator)
    allow(group_validator).to receive(:process)
  end

  describe "#process" do
    it "validates the groups" do
      expect(group_validator).to receive(:process)
      subject.process
    end

    it "creates the access control entries and adds the permissions to them" do
      subject.process
      portfolio.reload
      expect(portfolio.access_control_entries.first.permissions.count).to eq(2)
    end
  end
end
