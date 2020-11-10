class ServicePlan < ApplicationRecord
  include Discard::Model
  acts_as_tenant(:tenant)

  belongs_to :portfolio_item
  validates :base, :presence => true
  validate :modified_survey, :on => :update, :if => proc { modified.present? }
  validate :data_driven_form, :on => :update, :if => proc { modified.present? }

  def empty_schema?
    base["schemaType"].presence == "emptySchema"
  end

  def invalid_survey_message
    "The underlying survey on #{portfolio_item.name} in the #{portfolio_item.portfolio.name} portfolio has been changed and is no longer valid, please contact an administrator to fix it."
  end

  private

  def modified_survey
    if Catalog::SurveyCompare.changed?(self)
      raise Catalog::InvalidSurvey, invalid_survey_message
    end
  end

  def data_driven_form
    Catalog::DataDrivenFormValidator.valid?(modified)
  end
end
