shared_examples "aceable" do
  it { is_expected.to have_many(:access_control_entries) }
end
