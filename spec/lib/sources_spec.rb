describe Sources, :type => :current_forwardable do
  let(:sources_ex) { SourcesApiClient::ApiError.new("kaboom") }

  it "raises SourcesError" do
    with_modified_env :SOURCES_URL => 'http://source.example.com' do
      allow(Insights::API::Common::Request).to receive(:current_forwardable).and_return(:x => 1)
      expect do
        described_class.call do |_klass|
          raise sources_ex
        end
      end.to raise_exception(Catalog::SourcesError)
    end
  end
end
