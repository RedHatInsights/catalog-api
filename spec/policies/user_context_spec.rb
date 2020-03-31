describe UserContext, [:type => :current_forwardble] do
  let(:current_request) { Insights::API::Common::Request.new(default_request) }
  subject do
    described_class.new(current_request, "params")
  end

  describe "#access" do
    let(:insights_access) { instance_double(Insights::API::Common::RBAC::Access) }

    before do
      allow(Insights::API::Common::RBAC::Access).to receive(:new).and_return(insights_access)
      allow(insights_access).to receive(:process).and_return(insights_access)
    end

    it "fetches a memoized access list from RBAC" do
      expect(Insights::API::Common::RBAC::Access).to receive(:new).with("").once
      expect(insights_access).to receive(:process).once
      2.times { subject.access }
    end
  end

  describe "#rbac_enabled?" do
    before do
      allow(Insights::API::Common::RBAC::Access).to receive(:enabled?).and_return(true)
    end

    it "fetches a memoized enabled flag from RBAC" do
      expect(Insights::API::Common::RBAC::Access).to receive(:enabled?).once
      subject.rbac_enabled?
      expect(subject.rbac_enabled?).to be(true)
    end
  end

  describe "#group_uuids" do
    let(:rbac_api) { instance_double(Insights::API::Common::RBAC::Service) }

    before do
      allow(Insights::API::Common::RBAC::Service).to receive(:call).with(RBACApiClient::GroupApi).and_yield(rbac_api)
      allow(Insights::API::Common::RBAC::Service).to receive(:paginate).with(rbac_api, :list_groups, :scope => 'principal')
        .and_return(group_list)
    end

    let(:group_list) { [RBACApiClient::GroupOut.new(:name => "group", :uuid => "123-456")] }

    it "returns a memoized group uuid list" do
      expect(Insights::API::Common::RBAC::Service).to receive(:call).once
      subject.group_uuids
      expect(subject.group_uuids).to eq(["123-456"])
    end
  end
end
