describe UserContext, [:type => :current_forwardble] do
  let(:current_request) { Insights::API::Common::Request.new(default_request) }
  let(:app_filter) { "catalog,approval" }
  subject do
    described_class.new(current_request, "params")
  end

  describe "#access" do
    let(:insights_access) { instance_double(Insights::API::Common::RBAC::Access) }

    before do
      allow(Insights::API::Common::RBAC::Access).to receive(:new).with(app_filter).and_return(insights_access)
      allow(insights_access).to receive(:process).and_return(insights_access)
    end

    it "fetches a memoized access list from RBAC" do
      expect(Insights::API::Common::RBAC::Access).to receive(:new).with(app_filter).once
      expect(insights_access).to receive(:process).once
      2.times { subject.access }
    end
  end

  describe ".with_user_context" do
    it "uses the given user" do
      expect(Thread.current[:user_context]).to be_nil
      UserContext.with_user_context(subject) do |uc|
        expect(uc).to eq(subject)
        expect(Thread.current[:user_context]).not_to be_nil
      end
      expect(Thread.current[:user_context]).to be_nil
    end
  end

  describe ".current_user_context" do
    it "uses the given user" do
      expect(UserContext.current_user_context).to be_nil
      UserContext.with_user_context(subject) do
        expect(UserContext.current_user_context).not_to be_nil
      end
      expect(UserContext.current_user_context).to be_nil
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

  describe "#group_names" do
    let(:rbac_api) { instance_double(Insights::API::Common::RBAC::Service) }

    before do
      allow(Insights::API::Common::RBAC::Service).to receive(:call).with(RBACApiClient::GroupApi).and_yield(rbac_api)
      options = {:limit => 500, :uuid => uuids}
      allow(Insights::API::Common::RBAC::Service).to receive(:paginate).with(rbac_api, :list_groups, options)
        .and_return(group_list)
    end

    let(:group_list) do
      [
        RBACApiClient::GroupOut.new(:name => "group", :uuid => "123-456"),
        RBACApiClient::GroupOut.new(:name => "group2", :uuid => "123-4567")
      ]
    end

    context "when uuids are passed in" do
      let(:uuids) { %w[123-456] }

      it "ignores values not in the filter and returns a memoized hash" do
        expect(Insights::API::Common::RBAC::Service).to receive(:call).once
        subject.group_names(uuids)
        expect(subject.group_names(uuids)).to eq({"123-456" => "group"})
      end
    end

    context "when there are no uuids" do
      let(:uuids) { [] }

      it "returns a memoized empty hash" do
        expect(Insights::API::Common::RBAC::Service).to receive(:call).once
        subject.group_names(uuids)
        expect(subject.group_names(uuids)).to eq({})
      end
    end
  end
end
