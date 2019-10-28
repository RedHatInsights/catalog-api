class PortfolioItem < ApplicationRecord
  include OwnerField
  include Discard::Model
  include Catalog::DiscardRestore
  destroy_dependencies :service_plans

  acts_as_tenant(:tenant)
  acts_as_taggable_on

  default_scope -> { kept }

  has_many :icons, :as => :iconable, :inverse_of => :iconable, :dependent => :destroy
  has_many :service_plans, :dependent => :destroy
  belongs_to :portfolio, :optional => true
  validates :service_offering_ref, :name, :presence => true
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
    Approval::Service.call(ApprovalApiClient::WorkflowApi) { |api| api.show_workflow(workflow_ref) }
  rescue Catalog::ApprovalError
    errors.add(:workflow, "invalid")
    throw :abort
  end
end
