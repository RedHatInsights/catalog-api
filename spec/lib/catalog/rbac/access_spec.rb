describe Catalog::RBAC::Access, :type => [:current_forwardable] do
  let(:current_user) { Insights::API::Common::User.new("identity") }
  let(:current_request) { Insights::API::Common::Request.new(:user => current_user, :headers => "headers", :original_url => "original_url") }
  let(:params) { {:id => "321"} }
  let(:controller_name) { "portfolio_items" }
  let(:user_context) { UserContext.new(current_request, params, controller_name) }
  let(:subject) { described_class.new(user_context) }

  around do |example|
    with_modified_env(:RBAC_URL => "http://rbac.example.com") do
      example.call
    end
  end

  before do
    allow(Insights::API::Common::RBAC::Access).to receive(:enabled?).and_return(rbac_enabled)
  end

  shared_examples_for "permission checking" do |method, arguments, verb|
    context "when RBAC is enabled" do
      let(:rbac_enabled) { true }
      let(:access_pagination) do
        RBACApiClient::AccessPagination.new(
          :meta  => pagination_meta,
          :links => pagination_links,
          :data  => access_list
        )
      end
      let(:pagination_meta) { RBACApiClient::PaginationMeta.new(:count => 1) }
      let(:pagination_links) { RBACApiClient::PaginationLinks.new }

      before do
        stub_request(:get, "http://rbac.example.com/api/rbac/v1/access/?application=catalog&limit=500&offset=0")
          .to_return(
            :status  => 200,
            :body    => access_pagination.to_json,
            :headers => default_headers
          )
      end

      context "when the object is accessible" do
        let(:access_list) { [RBACApiClient::Access.new(:permission => ":portfolio_items:#{verb}")] }

        it "returns nil" do
          expect(subject.send(method, *arguments)).to eq(nil)
        end
      end

      context "when the object is not accessible" do
        let(:access_list) { [] }

        it "throws an error" do
          expect { subject.send(method, *arguments) }.to raise_error(Catalog::NotAuthorized, /access not authorized for/)
        end
      end
    end

    context "when RBAC is not enabled" do
      let(:rbac_enabled) { false }

      it "returns nil" do
        expect(subject.send(method, *arguments)).to eq(nil)
      end
    end
  end

  shared_examples_for "resource checking" do |method, arguments, verb, aceable_type, permission_under_test|
    context "when RBAC is enabled" do
      let(:rbac_enabled) { true }

      before do
        allow(Insights::API::Common::RBAC::Roles).to receive(:assigned_role?).with("Catalog Administrator").and_return(admin?)
      end

      context "when the user is not a catalog administrator" do
        let(:admin?) { false }
        let(:access_pagination) do
          RBACApiClient::AccessPagination.new(
            :meta  => pagination_meta,
            :links => pagination_links,
            :data  => access_list
          )
        end
        let(:group_pagination) do
          RBACApiClient::GroupPagination.new(
            :meta  => pagination_meta,
            :links => pagination_links,
            :data  => group_list
          )
        end
        let(:pagination_meta) { RBACApiClient::PaginationMeta.new(:count => 1) }
        let(:pagination_links) { RBACApiClient::PaginationLinks.new }

        before do
          stub_request(:get, "http://rbac.example.com/api/rbac/v1/groups/?limit=10&offset=0&scope=principal")
            .to_return(
              :status  => 200,
              :body    => group_pagination.to_json,
              :headers => default_headers
            )
          stub_request(:get, "http://rbac.example.com/api/rbac/v1/access/?application=catalog&limit=500&offset=0")
            .to_return(
              :status  => 200,
              :body    => access_pagination.to_json,
              :headers => default_headers
            )
        end

        context "when the object is accessible" do
          let(:access_list) { [RBACApiClient::Access.new(:permission => ":portfolio_items:#{verb}")] }
          let(:group_list) { [RBACApiClient::GroupOut.new(:name => "group", :uuid => "123-456")] }

          before do
            allow(aceable_type).to receive(:try).with(:supports_access_control?).and_return(supports_access_control?)
          end

          context "when the class supports access control" do
            let(:supports_access_control?) { true }

            before do
              create(:access_control_entry, permission_under_test, :aceable_id => aceable_id, :aceable_type => aceable_type)
            end

            context "when the ids exclude the given id" do
              let(:aceable_id) { "456" }

              it "raises an error" do
                expect { subject.send(method, *arguments) }.to raise_error(Catalog::NotAuthorized, /access not authorized for/)
              end
            end

            context "when the ids include the given id" do
              let(:aceable_id) { "321" }

              it "returns nil" do
                expect(subject.send(method, *arguments)).to eq(nil)
              end
            end
          end

          context "when the class does not support access control" do
            let(:supports_access_control?) { false }

            it "returns nil" do
              expect(subject.send(method, *arguments)).to eq(nil)
            end
          end
        end

        context "when the object is not accessible" do
          let(:access_list) { [] }
          let(:group_list) { [RBACApiClient::GroupOut.new(:name => "group", :uuid => "123-456")] }

          it "raises an error" do
            expect { subject.send(method, *arguments) }.to raise_error(Catalog::NotAuthorized, /access not authorized for/)
          end
        end
      end

      context "when the user is a catalog administrator" do
        let(:admin?) { true }

        it "returns nil" do
          expect(subject.send(method, *arguments)).to eq(nil)
        end
      end
    end

    context "when RBAC is not enabled" do
      let(:rbac_enabled) { false }

      it "returns nil" do
        expect(subject.send(method, *arguments)).to eq(nil)
      end
    end
  end

  describe "#create_access_check" do
    it_behaves_like "permission checking", :create_access_check, [], "create"
  end

  describe "#permission_check" do
    it_behaves_like "permission checking", :permission_check, ["verb", PortfolioItem], "verb"
  end

  describe "#resource_check" do
    it_behaves_like "resource checking", :resource_check, ["read", "321", Portfolio], "read", Portfolio, :has_read_permission
  end

  describe "#update_access_check" do
    it_behaves_like "resource checking", :update_access_check, [], "update", PortfolioItem, :has_update_permission
  end

  describe "#read_access_check" do
    it_behaves_like "resource checking", :read_access_check, [], "read", PortfolioItem, :has_read_permission
  end

  describe "#destroy_access_check" do
    it_behaves_like "resource checking", :destroy_access_check, [], "delete", PortfolioItem, :has_delete_permission
  end

  describe "#admin_check" do
    context "when RBAC is not enabled" do
      let(:rbac_enabled) { false }

      it "returns true" do
        expect(subject.admin_check).to eq(true)
      end
    end

    context "when RBAC is enabled" do
      let(:rbac_enabled) { true }

      before do
        allow(Catalog::RBAC::Role).to receive(:catalog_administrator?).and_return(catalog_administrator?)
      end

      context "when the user is a catalog administrator" do
        let(:catalog_administrator?) { true }

        it "returns true" do
          expect(subject.admin_check).to eq(true)
        end
      end

      context "when the user is not a catalog administrator" do
        let(:catalog_administrator?) { false }

        it "returns false" do
          expect(subject.admin_check).to eq(false)
        end
      end
    end
  end
end
