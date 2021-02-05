describe Api::V1x0::Catalog::ServicePlanCompare do
  let(:subject) { described_class.new(service_plan.id) }

  let(:service_plan) { create(:service_plan) }

  before do
    allow(::Catalog::SurveyCompare).to receive(:changed?).with(service_plan).and_return(changed)
  end

  describe "#process" do
    context "when the base has changed from inventory" do
      let(:changed) { true }

      it "raises a Catalog::InvalidSurvey error" do
        expect { subject.process }.to raise_error(::Catalog::InvalidSurvey, /The underlying survey.*has been changed/)
      end
    end

    context "when the base has not changed from inventory" do
      let(:changed) { false }

      it "does not raise an error" do
        expect { subject.process }.not_to raise_error
      end

      it "sets the service plan attribute" do
        expect(subject.process.service_plan).to eq(service_plan)
      end
    end
  end
end
