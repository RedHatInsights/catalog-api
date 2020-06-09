describe Catalog::DataDrivenFormValidator do
  let(:subject) { described_class.valid?(ddf) }
  let(:ddf_file) { File.read(Rails.root.join("spec", "support", "ddf", "valid_service_plan_ddf.json")) }
  let(:ddfv2_file) { File.read(Rails.root.join("spec", "support", "ddf", "valid_service_plan_ddf_v2.json")) }

  shared_examples_for "fails validation" do
    it "blows up" do
      expect { subject }.to raise_exception(Catalog::InvalidSurvey)
    end
  end

  describe "#valid?" do
    context "when given valid DDF JSON" do
      let(:ddf) { ddf_file }
      it "validates successfully" do
        expect(subject).to eq true
      end
    end

    context "when given valid DDFv2 JSON" do
      let(:ddf) { ddfv2_file }
      it "validates successfully" do
        expect(subject).to eq true
      end
    end

    context "when giving a invalid validator" do
      let(:ddf) do
        JSON.parse(ddf_file).with_indifferent_access.tap do |invalid|
          invalid[:schema][:fields].first[:validate].first[:type] = "not-a-real-validator"
        end.to_json
      end

      it_behaves_like "fails validation"
    end

    context "when giving a invalid component" do
      let(:ddf) do
        JSON.parse(ddf_file).with_indifferent_access.tap do |invalid|
          invalid[:schema][:fields].first[:component] = "not-a-real-component"
        end.to_json
      end

      it_behaves_like "fails validation"
    end

    context "when giving a invalid datatype" do
      let(:ddf) do
        JSON.parse(ddf_file).with_indifferent_access.tap do |invalid|
          invalid[:schema][:fields].first[:dataType] = "not-a-real-data-type"
        end.to_json
      end

      it_behaves_like "fails validation"
    end

    context "when giving a bad option" do
      let(:ddf) do
        JSON.parse(ddf_file).with_indifferent_access.tap do |invalid|
          invalid[:schema][:fields].second[:options].first.delete(:label)
        end.to_json
      end

      it_behaves_like "fails validation"
    end

    context "when giving a bad length validator" do
      let(:ddf) do
        JSON.parse(ddf_file).with_indifferent_access.tap do |invalid|
          invalid[:schema][:fields].first[:validate].second.delete(:threshold)
        end.to_json
      end

      it_behaves_like "fails validation"
    end

    context "when giving a bad number validator" do
      let(:ddf) do
        JSON.parse(ddf_file).with_indifferent_access.tap do |invalid|
          invalid[:schema][:fields].third[:validate].first.delete(:value)
        end.to_json
      end

      it_behaves_like "fails validation"
    end
  end
end
