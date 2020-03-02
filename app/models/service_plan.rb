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

  def orderable?
    !Catalog::SurveyCompare.changed?(self)
  end

  private

  def modified_survey
    raise Catalog::InvalidSurvey, "Base survey does not match Topology" unless orderable?
  end

  def data_driven_form
    Catalog::DataDrivenFormValidator.valid?(modified)
  end
end
