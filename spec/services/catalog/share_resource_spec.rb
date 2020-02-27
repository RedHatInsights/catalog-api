describe Catalog::ShareResource, :type => :service do
  let(:portfolio) { create(:portfolio) }

  let(:params) do
    {
      :group_uuids => ["123"],
      :permissions => %w[read update],
      :object      => portfolio
    }
  end
  let(:rbac_group) { instance_double(Catalog::RBAC::Group) }

  let(:subject) { described_class.new(params) }

  before do
    allow(Catalog::RBAC::Group).to receive(:new).with(["123"]).and_return(rbac_group)
    allow(rbac_group).to receive(:check)
  end

  describe "#process" do
    it "checks the groups" do
      expect(rbac_group).to receive(:check)
      subject.process
    end

    it "creates the access control entries and adds the permissions to them" do
      subject.process
      portfolio.reload
      expect(portfolio.access_control_entries.first.permissions.count).to eq(2)
    end
  end
end
