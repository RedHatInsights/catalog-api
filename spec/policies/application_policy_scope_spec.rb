describe ApplicationPolicy::Scope, :type => [:service] do
  let(:user_context) { instance_double(UserContext, :group_uuids => ["123-456"]) }
  let(:scope) { Portfolio }
  let(:subject) { described_class.new(user_context, scope) }

  describe "#resolve" do
    let(:portfolio) { create(:portfolio) }

    it "returns all of the requested objects" do
      expect(subject.resolve).to contain_exactly(portfolio)
    end
  end
end
