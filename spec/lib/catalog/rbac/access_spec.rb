describe Catalog::RBAC::Access, :type => [:current_forwardable] do
  let(:current_request) { Insights::API::Common::Request.new(default_request) }
  let(:user_context) { UserContext.new(current_request, nil) }

  let(:subject) { described_class.new(user_context, portfolio) }
  let(:portfolio_item) { create(:portfolio_item, :portfolio => portfolio) }
  let(:portfolio) { create(:portfolio, :id => "321") }
  let(:order) { create(:order, :id => "456") }
  let(:order_item) { create(:order_item, :order => order, :portfolio_item => portfolio_item) }

  around do |example|
    Insights::API::Common::Request.with_request(current_request) do
      example.call
    end
  end

  let(:catalog_access) { instance_double(Insights::API::Common::RBAC::Access) }

  before do
    allow(Insights::API::Common::RBAC::Access).to receive(:enabled?).and_return(rbac_enabled)
    allow(user_context).to receive(:access).and_return(catalog_access)
    allow(user_context).to receive(:group_uuids).and_return(["123-456"])
  end

  shared_examples_for "permission checking" do |method, arguments, verb|
    context "when RBAC is enabled" do
      let(:rbac_enabled) { true }

      before do
        allow(catalog_access).to receive(:accessible?).with("portfolios", verb).and_return(accessible)
      end

      context "when the object is accessible" do
        let(:accessible) { true }

        it "returns true" do
          expect(subject.send(method, *arguments)).to eq(true)
        end
      end

      context "when the object is not accessible" do
        let(:accessible) { false }

        it "returns false" do
          expect(subject.send(method, *arguments)).to eq(false)
        end
      end
    end

    context "when RBAC is not enabled" do
      let(:rbac_enabled) { false }

      it "returns true" do
        expect(subject.send(method, *arguments)).to eq(true)
      end
    end
  end

  shared_examples_for "resource checking" do |method, arguments, verb, aceable_type, permission_under_test|
    context "when RBAC is enabled" do
      let(:rbac_enabled) { true }

      before do
        allow(catalog_access).to receive(:scopes).with(aceable_type.table_name, verb).and_return(scopes)
      end

      context "when the user is in the group scope" do
        let(:scopes) { %w[group user] }

        before do
          create(:access_control_entry, permission_under_test, :aceable_id => aceable_id, :aceable_type => aceable_type)
        end

        context "when the ids exclude the given id" do
          let(:aceable_id) { "456" }

          it "returns false" do
            expect(subject.send(method, *arguments)).to eq(false)
          end
        end

        context "when the ids include the given id" do
          let(:aceable_id) { portfolio.id }

          it "returns true" do
            expect(subject.send(method, *arguments)).to eq(true)
          end
        end
      end

      context "when the user is only in the user scope" do
        let(:scopes) { %w[user] }

        context "when the username matches the record owner" do
          it "returns true" do
            expect(subject.send(method, *arguments)).to eq(true)
          end
        end

        context "when the username does not match the record owner" do
          before do
            allow(portfolio).to receive(:owner).and_return("notjdoe")
            allow(order).to receive(:owner).and_return("notjdoe")
          end

          it "returns false" do
            expect(subject.send(method, *arguments)).to eq(false)
          end
        end
      end

      context "when the user is in the admin scope" do
        let(:scopes) { %w[admin group user] }

        it "returns true" do
          expect(subject.send(method, *arguments)).to eq(true)
        end
      end

      context "when the user has no scopes" do
        let(:scopes) { [] }

        it "logs messages" do
          allow(Rails.logger).to receive(:debug)
          subject.send(method, *arguments)

          expect(Rails.logger).to have_received(:debug).with(/Scope does not include admin, group, or user/)
        end

        it "returns false" do
          expect(subject.send(method, *arguments)).to eq(false)
        end
      end
    end

    context "when RBAC is not enabled" do
      let(:rbac_enabled) { false }

      it "returns true" do
        expect(subject.send(method, *arguments)).to eq(true)
      end
    end
  end

  describe "#create_access_check" do
    it_behaves_like "permission checking", :create_access_check, [Portfolio], "create"
  end

  describe "#permission_check" do
    it_behaves_like "permission checking", :permission_check, ["verb", Portfolio], "verb"
  end

  describe "#resource_check" do
    it_behaves_like "resource checking", :resource_check, ["read", "321", Portfolio], "read", Portfolio, :has_read_permission
  end

  describe "#resource_check for order" do
    let(:subject) { described_class.new(user_context, order) }

    it_behaves_like "resource checking", :resource_check, ["order", "321", Portfolio], "order", Portfolio, :has_order_permission
  end

  describe "#update_access_check" do
    it_behaves_like "resource checking", :update_access_check, [], "update", Portfolio, :has_update_permission
  end

  describe "#read_access_check" do
    it_behaves_like "resource checking", :read_access_check, [], "read", Portfolio, :has_read_permission
  end

  describe "#destroy_access_check" do
    it_behaves_like "resource checking", :destroy_access_check, [], "delete", Portfolio, :has_delete_permission
  end

  describe "#admin_access_check" do
    context "when RBAC is enabled" do
      let(:rbac_enabled) { true }

      before do
        allow(catalog_access).to receive(:admin_scope?).with("portfolios", "update").and_return(admin_scope)
      end

      context "when the user has admin scopes for the specified object" do
        let(:admin_scope) { true }

        it "returns true" do
          expect(subject.admin_access_check("portfolios", "update")).to eq(true)
        end
      end

      context "when the user does not have admin scopes for the specified object" do
        let(:admin_scope) { false }

        it "returns false" do
          expect(subject.admin_access_check("portfolios", "update")).to eq(false)
        end
      end
    end

    context "when RBAC is not enabled" do
      let(:rbac_enabled) { false }

      it "returns true" do
        expect(subject.admin_access_check("portfolios", "update")).to eq(true)
      end
    end
  end

  describe "#approval_workflow_check" do
    context "when RBAC is enabled" do
      let(:rbac_enabled) { true }

      let(:read_accessible?) { true }
      let(:link_accessible?) { true }
      let(:unlink_accessible?) { true }

      before do
        allow(catalog_access).to receive(:accessible?).with("workflows", "read", "approval").and_return(read_accessible?)
        allow(catalog_access).to receive(:accessible?).with("workflows", "link", "approval").and_return(link_accessible?)
        allow(catalog_access).to receive(:accessible?).with("workflows", "unlink", "approval").and_return(unlink_accessible?)
      end

      context "when the user has admin scopes for read, link, and unlink" do
        it "returns true" do
          expect(subject.approval_workflow_check).to eq(true)
        end
      end

      context "when the user does not have admin scopes for read" do
        let(:read_accessible?) { false }

        it "returns false" do
          expect(subject.approval_workflow_check).to eq(false)
        end
      end

      context "when the user does not have admin scopes for link" do
        let(:link_accessible?) { false }

        it "returns false" do
          expect(subject.approval_workflow_check).to eq(false)
        end
      end

      context "when the user does not have admin scopes for unlink" do
        let(:unlink_accessible?) { false }

        it "returns false" do
          expect(subject.approval_workflow_check).to eq(false)
        end
      end
    end

    context "when RBAC is not enabled" do
      let(:rbac_enabled) { false }

      it "returns true" do
        expect(subject.admin_access_check("portfolios", "update")).to eq(true)
      end
    end
  end
end
