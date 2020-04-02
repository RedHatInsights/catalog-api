class PortfolioItem < ApplicationRecord
  include OwnerField
  include Discard::Model
  include Catalog::DiscardRestore
  destroy_dependencies :service_plans

  acts_as_tenant(:tenant)
  acts_as_taggable_on

  default_scope -> { kept.order(Arel.sql('LOWER(portfolio_items.name)')) }

  belongs_to :icon, :optional => true
  has_many :service_plans, :dependent => :destroy
  belongs_to :portfolio
  validates :service_offering_ref, :name, :presence => true
  validates :favorite_before_type_cast, :format => { :with => /\A(true|false)\z/i }, :allow_blank => true

  attribute :metadata, ActiveRecord::Type::Json.new

  def metadata
    {:user_capabilities => user_capabilities}
  end

  private

  def user_capabilities
    return nil if Thread.current[:user].nil?

    user = Thread.current[:user]
    PortfolioItemPolicy.new(user, self).user_capabilities
  end
end
