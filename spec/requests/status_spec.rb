RSpec.describe StatusController, :type => :request do
  it "mixes in the insights status API endpoints" do
    expect(StatusController.ancestors.include?(Insights::API::Common::Status::Api)).to be_truthy
  end
end
