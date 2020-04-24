describe ApplicationPolicy do
  let(:user_context) { instance_double(UserContext, :group_uuids => ["123-456"]) }
  let(:record) { create(:portfolio) }
  let(:subject) { described_class.new(user_context, record) }

  it "#index?" do
    expect(subject.index?).to be_falsey
  end

  it "#show?" do
    expect(subject.show?).to be_falsey
  end

  it "#create?" do
    expect(subject.show?).to be_falsey
  end

  it "#new?" do
    expect(subject.show?).to be_falsey
  end

  it "#update?" do
    expect(subject.show?).to be_falsey
  end

  it "#edit?" do
    expect(subject.show?).to be_falsey
  end

  it "#destroy?" do
    expect(subject.destroy?).to be_falsey
  end

  it "#user_capabilities" do
    result = {'edit'    => false,
              'update'  => false,
              'create'  => false,
              'destroy' => false,
              'show'    => false,
              'new'     => false }
    expect(subject.user_capabilities).to include(result)
  end
end
