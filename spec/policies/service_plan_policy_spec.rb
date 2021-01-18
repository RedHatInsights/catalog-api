describe ServicePlanPolicy do
  let(:portfolio) { create(:portfolio) }
  let(:portfolio_item) { create(:portfolio_item, :portfolio => portfolio) }
  let(:service_plan) { create(:service_plan, :portfolio_item => portfolio_item) }

  let(:user_context) { UserContext.new("current_request", "params") }
  let(:rbac_access) { instance_double(Catalog::RBAC::Access) }

  subject { described_class.new(user_context, service_plan) }

  before do
    allow(Catalog::RBAC::Access).to receive(:new).with(user_context, service_plan).and_return(rbac_access)
    allow(rbac_access).to receive(:resource_check).with("update", portfolio.id, Portfolio).and_return(true)
  end

  describe "#create?" do
    subject { described_class.new(user_context, portfolio) }

    before do
      allow(Catalog::RBAC::Access).to receive(:new).with(user_context, portfolio).and_return(rbac_access)
    end

    it "delegates to the rbac_access resource check with the portfolio" do
      expect(rbac_access).to receive(:resource_check).with("update", portfolio.id, Portfolio).and_return(true)
      expect(subject.create?).to eq(true)
    end

    it "sets the error message to denote the record is a service plan" do
      subject.create?
      expect(subject.error_message).to eq("You are not authorized to perform the create action for this service plan")
    end
  end

  describe "#update_modified?" do
    it "delegates to the rbac_access resource check" do
      expect(rbac_access).to receive(:resource_check).with("update", portfolio.id, Portfolio).and_return(true)
      expect(subject.update_modified?).to eq(true)
    end

    it "sets the error message to denote the record is a service plan" do
      subject.update_modified?
      expect(subject.error_message).to eq("You are not authorized to perform the update_modified action for this service plan")
    end
  end

  describe "#reset?" do
    it "delegates to the rbac_access resource check" do
      expect(rbac_access).to receive(:resource_check).with("update", portfolio.id, Portfolio).and_return(true)
      expect(subject.reset?).to eq(true)
    end

    it "sets the error message to denote the record is a service plan" do
      subject.reset?
      expect(subject.error_message).to eq("You are not authorized to perform the reset action for this service plan")
    end
  end
end
