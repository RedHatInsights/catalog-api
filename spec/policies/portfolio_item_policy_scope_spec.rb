describe PortfolioItemPolicy::Scope, :type => [:service] do
  let(:user) { nil }
  let(:scope) { PortfolioItem }
  let(:subject) { described_class.new(user, scope) }

  describe "#resolve" do
    let(:portfolio) { create(:portfolio) }
    let!(:portfolio_item1) { create(:portfolio_item, :portfolio => portfolio) }
    let!(:portfolio_item2) { create(:portfolio_item) }

    around do |example|
      with_modified_env(:RBAC_URL => "http://rbac") do
        Insights::API::Common::Request.with_request(default_request) { example.call }
      end
    end

    before do
      allow(Insights::API::Common::RBAC::Roles).to receive(:assigned_role?).with("Catalog Administrator").and_return(admin?)
    end

    context "when the user is a catalog administrator" do
      let(:admin?) { true }

      it "returns all of the portfolio items" do
        expect(subject.resolve).to contain_exactly(portfolio_item1, portfolio_item2)
      end
    end

    context "when the user is not a catalog administrator" do
      let(:admin?) { false }
      let(:access_object) { instance_double(Insights::API::Common::RBAC::Access, :accessible? => accessible?) }

      before do
        allow(Insights::API::Common::RBAC::Access).to receive(:new).with('portfolios', 'read').and_return(access_object)
        allow(access_object).to receive(:process).and_return(access_object)
      end

      context "when the user does not have permission to read portfolios" do
        let(:accessible?) { false }

        it "raises a Catalog::NotAuthorized error" do
          expect { subject.resolve }.to raise_error(Catalog::NotAuthorized, "Not Authorized for portfolios")
        end
      end

      context "when the user has permission to read portfolios" do
        let(:accessible?) { true }
        let(:rbac_paginated_response) do
          RBACApiClient::GroupPagination.new(
            :meta => RBACApiClient::PaginationMeta.new(:count => 1),
            :data => [RBACApiClient::GroupOut.new(:uuid => "123-456")]
          )
        end

        before do
          stub_request(:get, "http://rbac/api/rbac/v1/groups/?limit=10&offset=0&scope=principal").to_return(
            :status  => 200,
            :body    => rbac_paginated_response.to_json,
            :headers => default_headers
          )
        end

        context "when the access control entries exist" do
          before do
            create(:access_control_entry, :has_read_permission, :aceable_id => portfolio.id)
          end

          it "returns the set limited by the correct portfolio ids" do
            expect(subject.resolve).to eq([portfolio_item1])
          end
        end

        context "when access control entries do not exist" do
          it "returns an empty set" do
            expect(subject.resolve).to eq([])
          end
        end
      end
    end
  end
end
