describe Approval::Service, :type => :current_forwardable do
  let(:topo_ex) { ApprovalApiClient::ApiError.new("kaboom") }

  it "raises ApprovalError" do
    with_modified_env :APPROVAL_URL => 'http://approval.example.com' do
      allow(Insights::API::Common::Request).to receive(:current_forwardable).and_return(:x => 1)
      expect do
        described_class.call(ApprovalApiClient::RequestApi) do |_api|
          raise topo_ex
        end
      end.to raise_exception(Catalog::ApprovalError)
    end
  end
end
