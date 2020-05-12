describe Api::V1x0::Catalog::ServicePlanJson, :type => :service do
  let(:service_plan) { create(:service_plan) }
  let(:subject) { described_class.new(params).process.json }
  let(:portfolio_item) { service_plan.portfolio_item }

  describe "#process" do
    context "when rending a service plan with no options" do
      let(:params) { {:service_plan_id => service_plan.id} }

      it "renders the specified service_plan schema" do
        expect(subject["create_json_schema"]).to eq service_plan.modified
      end
    end

    context "when rendering a service plan from a portfolio item" do
      let(:params) { {:portfolio_item_id => portfolio_item.id} }

      it "renders the specified service_plan schema" do
        expect(subject["create_json_schema"]).to eq service_plan.modified
      end
    end

    context "when rendering a service plan from a list of service plans" do
      let(:params) { {:service_plans => [service_plan]} }

      it "renders the specified service_plan schema" do
        expect(subject["create_json_schema"]).to eq service_plan.modified
      end
    end

    context "when specifying the collection flag" do
      let(:params) { {:service_plan_id => service_plan.id, :collection => true} }

      it "returns a collection" do
        expect(subject.class).to eq Array
      end
    end

    context "when specifying the schema type" do
      let(:params) { {:service_plan_id => service_plan.id, :schema => "base"} }

      it "returns the specified schema" do
        expect(subject["create_json_schema"]).to eq service_plan.base
      end
    end
  end
end
