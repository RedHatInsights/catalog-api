describe Approval::Service, :type => :current_forwardable do
  let(:topo_ex) { ApprovalApiClient::ApiError.new("kaboom") }

  it "raises ApprovalError" do
    with_modified_env :APPROVAL_URL => 'http://www.example.com' do
      expect do
        described_class.call(ApprovalApiClient::RequestApi) do |_api|
          raise topo_ex
        end
      end.to raise_exception(Catalog::ApprovalError)
    end
  end
end
