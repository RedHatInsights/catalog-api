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

  private

  def modified_survey
    if Catalog::SurveyCompare.changed?(self)
      raise Catalog::InvalidSurvey, "Base survey does not match Topology"
    end
  end

  def data_driven_form
    Catalog::DataDrivenFormValidator.valid?(modified)
  end
end
