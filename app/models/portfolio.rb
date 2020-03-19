class Portfolio < ApplicationRecord
  include OwnerField
  include Discard::Model
  include Catalog::DiscardRestore
  include Aceable
  destroy_dependencies :portfolio_items

  acts_as_tenant(:tenant)
  acts_as_taggable_on
  default_scope -> { kept }
  belongs_to :icon, :optional => true

  validates :name, :presence => true, :uniqueness => { :scope => %i(tenant_id discarded_at) }
  validates :enabled_before_type_cast, :format => { :with => /\A(true|false)\z/i }, :allow_blank => true

  has_many :portfolio_items, :dependent => :destroy

  def add_portfolio_item(portfolio_item)
    portfolio_items << portfolio_item
  end

  attribute :metadata, ActiveRecord::Type::Json.new

  def metadata
    user = Insights::API::Common::Request.current!

    {:user_capabilities => PortfolioPolicy.new(user, self).user_capabilities}
  end
end
