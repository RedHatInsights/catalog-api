describe RBAC::Service do
  let(:rbac_ex) { RBACApiClient::ApiError.new("kaboom") }
  let(:page_size) { 3 }
  let(:page1_data) { [1, 2, 3] }
  let(:page2_data) { [4, 5, 6] }
  let(:page1_args) { { 'page' => 1, 'page_size' => page_size } }
  let(:page2_args) { { 'page' => 2, 'page_size' => page_size } }
  let(:meta) { double('count' => 6) }
  let(:result1) { double(:meta => meta, :data => page1_data) }
  let(:result2) { double(:meta => meta, :data => page2_data) }
  let(:obj) { double }

  it "raises RBACError" do
    with_modified_env :RBAC_URL => 'http://www.example.com' do
      allow(ManageIQ::API::Common::Headers).to receive(:current_forwardable).and_return(:x => 1)
      expect do
        described_class.call(RBACApiClient::StatusApi) do |_klass|
          raise rbac_ex
        end
      end.to raise_exception(ServiceCatalog::RBACError)
    end
  end

  context "pagination" do
    it "paginates" do
      allow(obj).to receive(:dummy).with(page1_args).and_return(result1)
      allow(obj).to receive(:dummy).with(page2_args).and_return(result2)
      expect(described_class.paginate(obj, :dummy, 'page_size' => page_size).to_a.size).to eq(6)
    end

    it "paginates with extra_args" do
      allow(obj).to receive(:dummy).with("extra_arg", page1_args).and_return(result1)
      allow(obj).to receive(:dummy).with("extra_arg", page2_args).and_return(result2)
      expect(described_class.paginate(obj, :dummy, { 'page_size' => 3 }, "extra_arg").to_a.size).to eq(6)
    end

    it "handles exception" do
      allow(obj).to receive(:dummy).with(page1_args).and_raise(StandardError.new("kaboom"))
      expect do
        described_class.paginate(obj, :dummy, 'page_size' => 3).to_a
      end.to raise_exception(StandardError)
    end
  end
end
