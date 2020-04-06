class Portfolio < ApplicationRecord
  include OwnerField
  include Discard::Model
  include Catalog::DiscardRestore
  include Aceable
  include Catalog::UserCapabilities

  destroy_dependencies :portfolio_items

  acts_as_tenant(:tenant)
  acts_as_taggable_on
  default_scope -> { kept.order(Arel.sql('LOWER(portfolios.name)')) }
  belongs_to :icon, :optional => true

  validates :name, :presence => true, :uniqueness => { :scope => %i(tenant_id discarded_at) }
  validates :enabled_before_type_cast, :format => { :with => /\A(true|false)\z/i }, :allow_blank => true

  has_many :portfolio_items, :dependent => :destroy

  def add_portfolio_item(portfolio_item)
    portfolio_items << portfolio_item
  end

  def metadata
    x = {:user_capabilities        => user_capabilities}
    if ENV['IGNORE_EXTRAS'] == 'true'
      x
    else
      x.merge(extras)
    end
  end

  def extras
    {:groups_shared_count      => access_control_entries.select(:group_uuid).distinct.count,
     :approval_processes_count => tags.where(:name => "workflows", :namespace => "approval").count,
     :product_count            => self.portfolio_items.count}
  end

end
