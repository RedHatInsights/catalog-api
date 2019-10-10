class Portfolio < ApplicationRecord
  include OwnerField
  include Discard::Model
  include Catalog::DiscardRestore
  destroy_dependencies :portfolio_items

  acts_as_tenant(:tenant)
  acts_as_taggable_on
  default_scope -> { kept }
  has_many :icons, :as => :iconable, :inverse_of => :iconable, :dependent => :destroy

  validates :name, :presence => true, :uniqueness => { :scope => %i(tenant_id discarded_at) }
  validates :image_url, :format => { :with => URI::DEFAULT_PARSER.make_regexp }, :allow_blank => true
  validates :enabled_before_type_cast, :format => { :with => /\A(true|false)\z/i }, :allow_blank => true

  has_many :portfolio_items, :dependent => :destroy

  def add_portfolio_item(portfolio_item)
    portfolio_items << portfolio_item
  end
end
