describe Approval do
  let(:topo_ex) { ApprovalApiClient::ApiError.new("kaboom") }

  it "raises ApprovalError" do
    with_modified_env :APPROVAL_URL => 'http://www.example.com' do
      allow(ManageIQ::API::Common::Request).to receive(:current_forwardable).and_return(:x => 1)
      expect do
        described_class.call do |_api|
          raise topo_ex
        end
      end.to raise_exception(Catalog::ApprovalError)
    end
  end
end
