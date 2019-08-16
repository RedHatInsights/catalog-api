describe RBAC::Roles do
  let(:opts) { {:name => 'Catalog Administrator', :scope => 'principal'} }
  let(:response_headers) { {"Content-Type" => 'application/json'} }
  let(:catalog_admin) do
    { :data => data, :meta => { :count => count } }
  end

  around do |example|
    with_modified_env(:RBAC_URL => "http://localhost") do
      ManageIQ::API::Common::Request.with_request(default_request) { example.call }
    end
  end

  before do
    stub_request(:get, "http://localhost/api/rbac/v1/roles/?limit=10&name=Catalog%20Administrator&offset=0&scope=principal")
      .to_return(:status  => 200,
                 :body    => catalog_admin.to_json,
                 :headers => response_headers)
  end

  describe "#self.assigned_role?" do
    let(:assigned_role) { described_class.assigned_role?("Catalog Administrator") }

    context "when the role exists" do
      let(:data) do
        [{
          :name        => "Catalog Administrator",
          :description => "A catalog administrator roles grants read, write and order permissions"
        }]
      end
      let(:count) { 1 }

      it "returns true for assigned_role" do
        expect(assigned_role).to be_truthy
      end
    end

    context "when the role does not exist" do
      let(:data) { [] }
      let(:count) { 0 }

      it "returns false for assigned_role" do
        expect(assigned_role).to be_falsey
      end
    end
  end
end
