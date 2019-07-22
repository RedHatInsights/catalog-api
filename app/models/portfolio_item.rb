class PortfolioItem < ApplicationRecord
  include OwnerField
  include Discard::Model
  acts_as_tenant(:tenant)

  default_scope -> { kept }

  has_many :icons, :dependent => :destroy
  belongs_to :portfolio
  validates :service_offering_ref, :presence => true
  validates :favorite_before_type_cast, :format => { :with => /\A(true|false)\z/i }, :allow_blank => true

  validate :validate_workflow, :if => proc { workflow_ref.present? }, :on => %i[create update]

  def resolved_workflow_refs
    # TODO: Add lookup to platform workflow ref
    # https://github.com/ManageIQ/catalog-api/issues/164
    [item_workflow_ref].compact
  end

  private

  def item_workflow_ref
    [self, portfolio].detect(&:workflow_ref)&.workflow_ref
  end

  def validate_workflow
    raise Catalog::InvalidParameter if workflow_ref.blank?

    Approval::Service.call(ApprovalApiClient::WorkflowApi) { |api| api.show_workflow(workflow_ref) }
  rescue Catalog::ApprovalError
    raise Catalog::InvalidParameter, "Invalid workflow_ref"
  end
end
