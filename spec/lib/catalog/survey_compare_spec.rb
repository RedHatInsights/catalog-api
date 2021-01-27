describe Catalog::SurveyCompare, :type => [:current_forwardable, :inventory] do
  let!(:portfolio_item) { service_plan.portfolio_item }
  let!(:service_offering_ref) { portfolio_item.service_offering_ref }
  let(:valid_ddf) { JSON.parse(File.read(Rails.root.join("spec", "support", "ddf", "valid_service_plan_ddf.json"))) }
  let(:empty_ddf) { JSON.parse(File.read(Rails.root.join("spec", "support", "ddf", "no_service_plan_ddf.json"))) }

  let(:topo_service_plan) do
    CatalogInventoryApiClient::ServicePlan.new(
      :name               => "The Plan",
      :id                 => "1",
      :description        => "A Service Plan",
      :create_json_schema => valid_ddf
    )
  end

  let(:service_plan_response) { CatalogInventoryApiClient::ServicePlansCollection.new(:data => [topo_service_plan]) }

  before do
    stub_request(:get, catalog_inventory_url("service_offerings/#{service_offering_ref}/service_plans"))
      .to_return(:status => 200, :body => service_plan_response.to_json, :headers => default_headers)
  end

  describe "#changed?" do
    context "when the base has changed from inventory" do
      let(:service_plan) { create(:service_plan) }

      it "returns true" do
        expect(Catalog::SurveyCompare.changed?(service_plan)).to be true
      end
    end

    context "when the base has not changed from inventory" do
      let(:service_plan) { create(:service_plan, :base => valid_ddf) }

      it "returns false" do
        expect(Catalog::SurveyCompare.changed?(service_plan)).to be false
      end
    end
  end

  describe "#any_changed?" do
    let(:plans) { [service_plan] }

    context "when the base has changed from inventory" do
      let(:service_plan) { create(:service_plan) }

      it "returns true" do
        expect(Catalog::SurveyCompare.any_changed?(plans)).to be true
      end
    end

    context "when the base has not changed from inventory" do
      let(:service_plan) { create(:service_plan, :base => valid_ddf) }

      it "returns false" do
        expect(Catalog::SurveyCompare.any_changed?(plans)).to be false
      end
    end
  end

  describe "#collect_changed" do
    let(:plans) { [service_plan] }

    context "when the base has changed from inventory" do
      let(:service_plan) { create(:service_plan) }

      it "returns an array of the changed plans" do
        expect(Catalog::SurveyCompare.collect_changed(plans)).to eq(plans)
      end
    end

    context "when the base has not changed from inventory" do
      let(:service_plan) { create(:service_plan, :base => valid_ddf) }

      it "returns an empty array" do
        expect(Catalog::SurveyCompare.collect_changed(plans)).to eq([])
      end
    end
  end

  describe "empty?" do
    context "when an empty service plan exists" do
      let(:service_plan) { create(:service_plan, :base => empty_ddf) }

      it "returns false" do
        expect(Catalog::SurveyCompare.changed?(service_plan)).to be false
      end
    end

  end
end
