describe OrderPolicy do
  let(:order) { create(:order) }
  let!(:order_item) { create(:order_item, :order => order, :portfolio_item => portfolio_item) }
  let!(:order_item2) { create(:order_item, :order => order, :portfolio_item => portfolio_item2) }
  let(:portfolio_item) { create(:portfolio_item, :portfolio => portfolio) }
  let(:portfolio_item2) { create(:portfolio_item, :portfolio => portfolio2) }
  let(:portfolio) { create(:portfolio) }
  let(:portfolio2) { create(:portfolio) }
  let(:user_context) { UserContext.new("current_request", "params") }
  let(:rbac_access) { instance_double(Catalog::RBAC::Access) }

  let(:subject) { described_class.new(user_context, order) }

  before do
    allow(Catalog::RBAC::Access).to receive(:new).with(user_context, order).and_return(rbac_access)
  end

  describe "#show?" do
    it "delegates to the rbac access" do
      expect(rbac_access).to receive(:read_access_check).and_return(true)
      expect(subject.show?).to eq(true)
    end
  end

  describe "#submit_order?" do
    let(:service_offering) { instance_double(Catalog::ServiceOffering) }

    before do
      allow(Catalog::ServiceOffering).to receive(:new).with(order).and_return(service_offering)
      allow(service_offering).to receive(:process).and_return(service_offering)
      allow(rbac_access).to receive(:resource_check).with('order', portfolio.id, Portfolio).and_return(order_check)
      allow(rbac_access).to receive(:resource_check).with('order', portfolio2.id, Portfolio).and_return(order_check2)
    end

    context "when the resource check for ordering from all portfolios is false" do
      let(:order_check) { false }
      let(:order_check2) { false }

      it "returns false" do
        expect(subject.submit_order?).to eq(false)
      end
    end

    context "when the resource check for ordering from any portfolio is false" do
      let(:order_check) { false }
      let(:order_check2) { true }

      it "returns false" do
        expect(subject.submit_order?).to eq(false)
      end
    end

    context "when the resource check for ordering from any portfolio is false" do
      let(:order_check) { true }
      let(:order_check2) { false }

      it "returns false" do
        expect(subject.submit_order?).to eq(false)
      end
    end

    context "when the resource check for ordering from all portfolios is true" do
      let(:order_check) { true }
      let(:order_check2) { true }

      it "returns true" do
        expect(subject.submit_order?).to eq(true)
      end
    end
  end
end
