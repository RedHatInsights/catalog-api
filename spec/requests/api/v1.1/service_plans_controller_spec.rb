describe "v1.1 - ServicePlansRequests", :type => [:request, :v1x1, :topology] do
  let!(:portfolio) { create(:portfolio) }
  let!(:portfolio_item) { create(:portfolio_item, :portfolio => portfolio) }
  let(:service_plan) { create(:service_plan, :portfolio_item => portfolio_item) }
  let(:rbac_access) { instance_double(Catalog::RBAC::Access) }

  describe "#reset" do
    let(:service_plan_reset) do
      instance_double(Api::V1x1::Catalog::ServicePlanReset,
                      :status                  => status,
                      :reimported_service_plan => {"the" => "json"})
    end

    subject { post "#{api_version}/service_plans/#{service_plan.id}/reset", :headers => default_headers }

    before do |example|
      allow(Catalog::RBAC::Access).to receive(:new).and_return(rbac_access)
      allow(rbac_access).to receive(:resource_check).with('update', portfolio.id, Portfolio).and_return(true)
      allow(Api::V1x1::Catalog::ServicePlanReset).to receive(:new).with(service_plan.id.to_s).and_return(service_plan_reset)
      allow(service_plan_reset).to receive(:process).and_return(service_plan_reset)

      subject unless example.metadata[:subject_inside]
    end

    context "when the service plan reset status is ok" do
      let(:status) { :ok }

      it "returns a 200" do
        expect(response).to have_http_status :ok
      end

      it "returns the reset service plan's json" do
        expect(json).to eq({"the" => "json"})
      end

      it_behaves_like "action that tests authorization", :reset?, ServicePlan
    end

    context "when the service plan reset status is not ok" do
      let(:status) { :no_content }

      it "returns a 204" do
        expect(response).to have_http_status :no_content
      end

      it "does not return a body" do
        expect(response.body).to eq("")
      end

      it_behaves_like "action that tests authorization", :reset?, ServicePlan
    end
  end
end
