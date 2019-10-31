class ServicePlan < ApplicationRecord
  include Discard::Model
  acts_as_tenant(:tenant)

  belongs_to :portfolio_item
  validates :base, :presence => true
  validate :modified_survey, :on => :update

  private

  def modified_survey
    if Catalog::SurveyCompare.changed?(self)
      errors.add(:modified, "Base survey does not match Topology")
      throw :bad_request
    end
  end
end
