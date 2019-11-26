class PortfolioItem < ApplicationRecord
  include OwnerField
  include Discard::Model
  include Catalog::DiscardRestore
  destroy_dependencies :service_plans

  acts_as_tenant(:tenant)
  acts_as_taggable_on

  default_scope -> { kept }

  belongs_to :icon, :optional => true
  has_many :service_plans, :dependent => :destroy
  has_many :order_templates
  belongs_to :portfolio, :optional => true
  validates :service_offering_ref, :name, :presence => true
  validates :favorite_before_type_cast, :format => { :with => /\A(true|false)\z/i }, :allow_blank => true
end
