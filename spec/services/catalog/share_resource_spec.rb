describe Catalog::ShareResource, :type => :service do
  let(:portfolio) { create(:portfolio) }

  let(:params) do
    {
      :group_uuids => ["123"],
      :permissions => %w[read update],
      :object      => portfolio
    }
  end

  let(:subject) { described_class.new(params) }

  describe "#process" do
    it "creates the access control entries and adds the permissions to them" do
      subject.process
      portfolio.reload
      expect(portfolio.access_control_entries.first.permissions.count).to eq(2)
    end
  end
end
