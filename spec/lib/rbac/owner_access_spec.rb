describe RBAC::Access do
  include_context "rbac_objects"
  let(:verb) { 'read' }
  let(:rbac_access) { described_class.new(owner_resource, verb) }
  let(:api_instance) { double }
  let(:rs_class) { class_double("RBAC::Service").as_stubbed_const(:transfer_nested_constants => true) }

  before do
    allow(rs_class).to receive(:call).with(RBACApiClient::AccessApi).and_yield(api_instance)
  end

  shared_examples_for "#owner_scoped?" do
    it "validate scope" do
      with_modified_env :APP_NAME => app_name do
        allow(RBAC::Service).to receive(:paginate).with(api_instance, :get_principal_access, {}, app_name).and_return(acls)
        svc_obj = rbac_access.process
        expect(svc_obj.acl.count).to eq(acl_count)
        expect(svc_obj.accessible?).to be_truthy
        expect(svc_obj.owner_scoped?).to eq(result)
      end
    end
  end

  context "owner access" do
    let(:acls) { [owner_access] }
    let(:result) { true }
    let(:acl_count) { 1 }
    it_behaves_like "#owner_scoped?"
  end

  context "owner access and all access" do
    let(:acls) { [owner_access, all_access] }
    let(:result) { false }
    let(:acl_count) { 2 }
    it_behaves_like "#owner_scoped?"
  end
end
