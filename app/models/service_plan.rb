class ServicePlan < ApplicationRecord
  include Discard::Model
  acts_as_tenant(:tenant)

  belongs_to :portfolio_item
  validates :base, :presence => true
  validate :modified_survey, :on => :update

  private

  def modified_survey
    if Catalog::SurveyCompare.changed?(self)
      raise Catalog::InvalidSurvey, "Base survey does not match Topology"
    end
  end
end
