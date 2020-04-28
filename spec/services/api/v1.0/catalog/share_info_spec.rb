describe Api::V1x0::Catalog::ShareInfo, :type => :service do
  let(:portfolio) { create(:portfolio) }
  let(:user_context) { instance_double(UserContext, :group_names => group_names) }
  let(:params) { {:object => portfolio, :user_context => user_context} }

  subject { described_class.new(params) }

  describe "#process" do
    let(:uuid) { "123" }

    context "when there are existing permissions" do
      before do
        create(:access_control_entry, :has_read_and_update_permission, :group_uuid => uuid, :aceable => portfolio)
      end

      context "when the group uuids match with group names" do
        let(:group_names) { {"123" => "group_name"} }

        it "returns the sharing information" do
          result = subject.process.result
          expect(result).to match_array([:group_name => "group_name", :group_uuid => "123", :permissions => match_array(%w[read update])])
        end
      end

      context "when the group uuids do not match with group names" do
        let(:group_names) { {"1234" => "group_name"} }

        it "returns the (empty) sharing information" do
          result = subject.process.result
          expect(result).to match_array([])
        end

        it "logs a warning message" do
          expect(Rails.logger).to receive(:warn).with(/Skipping group UUID/)
          subject.process
        end
      end
    end

    context "when there are no existing permissions" do
      let(:group_names) { {"123" => "group_name"} }

      it "returns the (empty) sharing information" do
        result = subject.process.result
        expect(result).to match_array([])
      end
    end
  end
end
