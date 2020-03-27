class Portfolio < ApplicationRecord
  include OwnerField
  include Discard::Model
  include Api::V1x0::Catalog::DiscardRestore
  include Aceable
  include UserCapabilities

  destroy_dependencies :portfolio_items

  acts_as_tenant(:tenant)
  acts_as_taggable_on
  default_scope -> { kept.order(Arel.sql('LOWER(portfolios.name)')) }
  belongs_to :icon, :optional => true

  validates :name, :presence => true, :length => {:maximum => 64}, :uniqueness => { :scope => %i(tenant_id discarded_at) }
  validates :enabled_before_type_cast, :format => { :with => /\A(true|false)\z/i }, :allow_blank => true

  has_many :portfolio_items, :dependent => :destroy

  def add_portfolio_item(portfolio_item)
    portfolio_items << portfolio_item
  end

  def metadata
    {:user_capabilities => user_capabilities,
     :shared            => self.access_control_entries.any?}
  end
end
