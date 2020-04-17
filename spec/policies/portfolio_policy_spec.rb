describe PortfolioPolicy do
  let(:portfolio) { create(:portfolio) }
  let(:user_context) { UserContext.new("current_request", "params") }
  let(:rbac_access) { instance_double(Catalog::RBAC::Access) }

  let(:subject) { described_class.new(user_context, portfolio) }

  before do
    allow(Catalog::RBAC::Access).to receive(:new).with(user_context, portfolio).and_return(rbac_access)
  end

  shared_examples "a policy action that requires create access" do |method|
    it "delegates to the rbac access create check" do
      expect(rbac_access).to receive(:create_access_check).and_return(true)
      expect(subject.send(method)).to eq(true)
    end
  end

  describe "#show?" do
    it "delegates to the rbac access read check" do
      expect(rbac_access).to receive(:read_access_check).and_return(true)
      expect(subject.show?).to eq(true)
    end
  end

  # describe "#set_approval?" do
  #   it "delegates to the rbac access update check" do
  #     expect(rbac_access).to receive(:update_access_check).and_return(true)
  #     expect(subject.set_approval?).to eq(true)
  #   end
  # end

  describe "#destroy?" do
    it "delegates to the rbac access destroy check" do
      expect(rbac_access).to receive(:destroy_access_check).and_return(true)
      expect(subject.destroy?).to eq(true)
    end
  end

  [:create?, :copy?].each do |method|
    describe "##{method}" do
      it_behaves_like "a policy action that requires create access", method
    end
  end

  describe "#update?" do
    it "delegates to the rbac access update check" do
      expect(rbac_access).to receive(:update_access_check).and_return(true)
      expect(subject.update?).to eq(true)
    end
  end

  [:share?, :unshare?].each do |method|
    describe "##{method}" do
      it "delegates to the rbac access update check" do
        expect(rbac_access).to receive(:admin_access_check).with("portfolios", "update").and_return(true)
        expect(subject.send(method)).to eq(true)
      end
    end
  end

  describe "#user_capabilities" do
    before do
      allow(rbac_access).to receive(:read_access_check).and_return(true)
      allow(rbac_access).to receive(:create_access_check).and_return(true)
      allow(rbac_access).to receive(:destroy_access_check).and_return(true)
      allow(rbac_access).to receive(:update_access_check).and_return(true)
      allow(rbac_access).to receive(:admin_access_check).with("portfolios", "update").and_return(true)
    end

    it "returns a hash of user capabilities" do
      expect(subject.user_capabilities).to eq({
        "create"       => true,
        "update"       => true,
        "destroy"      => true,
        "copy"         => true,
        "share"        => true,
        "unshare"      => true,
        "show"         => true,
        # "set_approval" => true
      })
    end
  end
end
