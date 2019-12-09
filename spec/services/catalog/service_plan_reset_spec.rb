describe Catalog::ServicePlanReset do
  let(:subject) { described_class.new(service_plan.id) }

  describe "#process" do
    let!(:service_plan) { create(:service_plan, :modified => modified) }

    context "when the modified attribute is nil" do
      let(:modified) { nil }

      it "sets the status to a 204" do
        expect(subject.process.status).to eq(:no_content)
      end
    end

    context "when the modified attribute is not nil" do
      let(:modified) { "modified" }

      it "updates the plan to have a nil modified attribute" do
        subject.process
        service_plan.reload
        expect(service_plan.modified).to be_nil
      end

      it "sets the status to a 200" do
        expect(subject.process.status).to eq(:ok)
      end
    end
  end
end
