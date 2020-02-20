describe Catalog::UnshareResource, :type => :service do
  let(:portfolio) { create(:portfolio) }
  let(:uuid) { "123" }

  let(:params) do
    {
      :group_uuids => [uuid],
      :permissions => %w[read update],
      :object      => portfolio
    }
  end

  before do
    create(:access_control_entry, :has_read_permission, :group_uuid => uuid, :aceable => portfolio)
    create(:access_control_entry, :has_update_permission, :group_uuid => uuid, :aceable => portfolio)
  end

  let(:subject) { described_class.new(params) }

  describe "#process" do
    it "removes the access control entries on the portfolio" do
      expect(portfolio.access_control_entries.count).to eq(2)
      subject.process
      portfolio.reload
      expect(portfolio.access_control_entries.count).to eq(0)
    end
  end
end
