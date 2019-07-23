class PortfolioItem < ApplicationRecord
  include OwnerField
  include Discard::Model
  acts_as_tenant(:tenant)

  default_scope -> { kept }

  has_one :icon, :dependent => :destroy
  belongs_to :portfolio
  validates :service_offering_ref, :presence => true

  def add_icon(icon)
    self.icon = icon
  end

  def resolved_workflow_refs
    # TODO: Add lookup to platform workflow ref
    # https://github.com/ManageIQ/catalog-api/issues/164
    [item_workflow_ref].compact
  end

  private

  def item_workflow_ref
    [self, portfolio].detect(&:workflow_ref)&.workflow_ref
  end
end
