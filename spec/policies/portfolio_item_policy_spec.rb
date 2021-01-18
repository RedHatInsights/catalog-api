describe PortfolioItemPolicy do
  let(:portfolio_item) { create(:portfolio_item, :portfolio => portfolio) }
  let(:portfolio) { create(:portfolio) }
  let(:user_context) { UserContext.new("current_request", params) }
  let(:params) { {} }
  let(:rbac_access) { instance_double(Catalog::RBAC::Access) }

  subject { described_class.new(user_context, portfolio_item) }

  before do
    allow(Catalog::RBAC::Access).to receive(:new).with(user_context, portfolio_item).and_return(rbac_access)
  end

  describe "#index?" do
    it "delegates to the rbac access permission check on portfolios" do
      expect(rbac_access).to receive(:permission_check).with('read', Portfolio).and_return(true)
      expect(subject.index?).to eq(true)
    end
  end

  describe "#create?" do
    before do
      allow(rbac_access).to receive(:resource_check).with('update', portfolio.id, Portfolio).and_return(true)
    end

    context "when the record passed into the policy is a portfolio" do
      subject { described_class.new(user_context, portfolio) }

      before do
        allow(Catalog::RBAC::Access).to receive(:new).with(user_context, portfolio).and_return(rbac_access)
      end

      it "delegates to the check for update permissions on the portfolio" do
        expect(rbac_access).to receive(:resource_check).with('update', portfolio.id, Portfolio).and_return(true)
        expect(subject.create?).to eq(true)
      end

      it "sets the error message to denote the record is a portfolio item" do
        subject.create?
        expect(subject.error_message).to eq("You are not authorized to perform the create action for this portfolio item")
      end
    end

    context "when the record passed into the policy is a portfolio item" do
      it "delegates to the check for update permissions on the parent portfolio" do
        expect(rbac_access).to receive(:resource_check).with('update', portfolio.id, Portfolio).and_return(true)
        expect(subject.create?).to eq(true)
      end

      it "sets the error message to denote the record is a portfolio item" do
        subject.create?
        expect(subject.error_message).to eq("You are not authorized to perform the create action for this portfolio item")
      end
    end
  end

  describe "#update?" do
    before do
      allow(rbac_access).to receive(:resource_check).with('update', portfolio.id, Portfolio).and_return(true)
    end

    it "delegates to the check for update permissions on the portfolio" do
      expect(rbac_access).to receive(:resource_check).with('update', portfolio.id, Portfolio).and_return(true)
      expect(subject.update?).to eq(true)
    end

    it "sets the error message to denote the record is a portfolio item" do
      subject.update?
      expect(subject.error_message).to eq("You are not authorized to perform the update action for this portfolio item")
    end
  end

  describe "#edit_survey?" do
    before do
      allow(rbac_access).to receive(:resource_check).with('update', portfolio.id, Portfolio).and_return(true)
    end

    it "delegates to the check for update permissions on the portfolio" do
      expect(rbac_access).to receive(:resource_check).with('update', portfolio.id, Portfolio).and_return(true)
      expect(subject.edit_survey?).to eq(true)
    end

    it "sets the error message to denote the record is a portfolio item" do
      subject.edit_survey?
      expect(subject.error_message).to eq("You are not authorized to perform the edit_survey action for this portfolio item")
    end
  end

  %i[set_approval? tag? untag?].each do |action|
    describe "##{action}" do
      let(:resource_check) { true }
      let(:approval_workflow_check) { true }

      before do
        allow(rbac_access).to receive(:resource_check).with("update", portfolio.id, Portfolio).and_return(resource_check)
        allow(rbac_access).to receive(:approval_workflow_check).and_return(approval_workflow_check)
      end

      context "when the resource check is false" do
        let(:resource_check) { false }

        it "returns false" do
          expect(subject.send(action)).to eq(false)
        end
      end

      context "when the approval workflow check is false" do
        let(:approval_workflow_check) { false }

        it "returns false" do
          expect(subject.send(action)).to eq(false)
        end
      end

      context "when the resource check and the approval workflow check are true" do
        it "returns true" do
          expect(subject.send(action)).to eq(true)
        end
      end
    end
  end

  %i[destroy? restore?].each do |method|
    describe "##{method}" do
      before do
        allow(rbac_access).to receive(:resource_check).with('update', portfolio.id, Portfolio).and_return(true)
      end

      it "delegates to the check for update permissions on the portfolio" do
        expect(rbac_access).to receive(:resource_check).with('update', portfolio.id, Portfolio).and_return(true)
        expect(subject.send(method)).to eq(true)
      end

      it "sets the error message to denote the record is a portfolio item" do
        subject.send(method)
        expect(subject.error_message).to eq("You are not authorized to perform the #{method.to_s.delete_suffix('?')} action for this portfolio item")
      end
    end
  end

  describe "#show?" do
    before do
      allow(rbac_access).to receive(:resource_check).with('read', portfolio.id, Portfolio).and_return(true)
    end

    it "delegates to the check for read permissions on the portfolio" do
      expect(rbac_access).to receive(:resource_check).with('read', portfolio.id, Portfolio).and_return(true)
      expect(subject.show?).to eq(true)
    end

    it "sets the error message to denote the record is a portfolio item" do
      subject.show?
      expect(subject.error_message).to eq("You are not authorized to perform the show action for this portfolio item")
    end
  end

  describe "#copy?" do
    let(:source_read_check) { true }
    let(:destination_read_check) { true }
    let(:destination_update_check) { true }
    let(:source_id) { portfolio.id }
    let(:destination_id) { source_id }

    before do
      allow(rbac_access).to receive(:resource_check).with('read', source_id, Portfolio).and_return(source_read_check)
      allow(rbac_access).to receive(:resource_check).with('read', destination_id, Portfolio).and_return(destination_read_check)
      allow(rbac_access).to receive(:resource_check).with('update', destination_id, Portfolio).and_return(destination_update_check)
    end

    context "when the parameters contain a portfolio_id" do
      let(:params) { {:portfolio_id => destination_id} }

      context "when the portfolio id matches the record's portfolio id" do
        context "when destination reading is false" do
          let(:destination_read_check) { false }

          it "returns false" do
            expect(subject.copy?).to eq(false)
          end
        end

        context "when destination updating is false" do
          let(:destination_update_check) { false }

          it "returns false" do
            expect(subject.copy?).to eq(false)
          end
        end

        context "when both conditions are true" do
          it "returns true" do
            expect(subject.copy?).to eq(true)
          end
        end
      end

      context "when the portfolio id does not match the record's portfolio id" do
        let(:destination_id) { source_id + 1 }

        context "when source reading is false" do
          let(:source_read_check) { false }

          it "returns false" do
            expect(subject.copy?).to eq(false)
          end
        end

        context "when destination reading is false" do
          let(:destination_read_check) { false }

          it "returns false" do
            expect(subject.copy?).to eq(false)
          end
        end

        context "when destination updating is false" do
          let(:destination_update_check) { false }

          it "returns false" do
            expect(subject.copy?).to eq(false)
          end
        end

        context "when all three conditions are true" do
          it "returns true" do
            expect(subject.copy?).to eq(true)
          end
        end
      end
    end

    context "when the parameters do not contain a portfolio_id" do
      context "when destination reading is false" do
        let(:destination_read_check) { false }

        it "returns false" do
          expect(subject.copy?).to eq(false)
        end
      end

      context "when destination updating is false" do
        let(:destination_update_check) { false }

        it "returns false" do
          expect(subject.copy?).to eq(false)
        end
      end

      context "when both conditions are true" do
        it "returns true" do
          expect(subject.copy?).to eq(true)
        end
      end
    end

    context "when there are no parameters at all" do
      let(:user_context) { UserContext.new("current_request", nil) }

      context "when destination reading is false" do
        let(:destination_read_check) { false }

        it "returns false" do
          expect(subject.copy?).to eq(false)
        end
      end

      context "when destination updating is false" do
        let(:destination_update_check) { false }

        it "returns false" do
          expect(subject.copy?).to eq(false)
        end
      end

      context "when both conditions are true" do
        it "returns true" do
          expect(subject.copy?).to eq(true)
        end
      end
    end
  end

  describe "#set_order_process?" do
    it "delegates to the check for read/link/unlink permissions on the order process" do
      expect(rbac_access).to receive(:admin_access_check).with('order_processes', 'read').and_return(true)
      expect(rbac_access).to receive(:admin_access_check).with('order_processes', 'link').and_return(true)
      expect(rbac_access).to receive(:admin_access_check).with('order_processes', 'unlink').and_return(true)
      expect(subject.set_order_process?).to eq(true)
    end
  end

  describe "#user_capabilities" do
    before do
      # Index
      allow(rbac_access).to receive(:permission_check).with('read', Portfolio).and_return(true)

      # Create, Update, Destroy, and half of Copy
      allow(rbac_access).to receive(:resource_check).with('update', portfolio.id, Portfolio).and_return(true)

      # Other half of Copy
      allow(rbac_access).to receive(:resource_check).with('read', portfolio.id, Portfolio).and_return(true)

      # Set approval
      allow(rbac_access).to receive(:approval_workflow_check).and_return(true)

      # set order process
      allow(rbac_access).to receive(:admin_access_check).with('order_processes', 'read').and_return(true)
      allow(rbac_access).to receive(:admin_access_check).with('order_processes', 'link').and_return(true)
      allow(rbac_access).to receive(:admin_access_check).with('order_processes', 'unlink').and_return(true)
    end

    it "returns a hash of user capabilities" do
      expect(subject.user_capabilities).to eq(
        "create"            => true,
        "update"            => true,
        "destroy"           => true,
        "restore"           => true,
        "copy"              => true,
        "set_approval"      => true,
        "show"              => true,
        "edit_survey"       => true,
        "tag"               => true,
        "untag"             => true,
        "set_order_process" => true
      )
    end
  end
end
