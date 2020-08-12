RSpec.shared_examples "action that tests authorization" do |action, object|
  let(:object_policy) { instance_double("#{object || object_class}Policy") }

  it "delegates to the correct Policy with the #{action} action", :subject_inside do
    expect("#{object || object_class}Policy".constantize).to receive(:new).and_return(object_policy)
    expect(object_policy).to receive(action)

    subject
  end
end
