describe Sources::Service do
  let(:sources_ex) { SourcesApiClient::ApiError.new("kaboom") }

  it "raises SourcesError" do
    with_modified_env :SOURCES_URL => 'http://www.example.com' do
      allow(ManageIQ::API::Common::Request).to receive(:current_forwardable).and_return(:x => 1)
      expect do
        described_class.call(SourcesApiClient::DefaultApi) do |_klass|
          raise sources_ex
        end
      end.to raise_exception(Catalog::SourcesError)
    end
  end
end
