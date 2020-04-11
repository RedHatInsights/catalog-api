class Portfolio < ApplicationRecord
  include OwnerField
  include Discard::Model
  include Catalog::DiscardRestore
  include Aceable
  include UserCapabilities

  destroy_dependencies :portfolio_items

  before_save { self[:metadata] = static_metadata }

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
    # Merge dynamic user_capabilities properties
    self[:metadata].merge(:user_capabilities => user_capabilities)
  end

  def update_metadata
    current_metadata = static_metadata
    return if current_metadata.eql?(self[:metadata])

    update(:metadata => current_metadata)
  end

  private

  def static_metadata
    {'statistics' =>
                     {
                       'approval_processes' => tags.where(:name => 'workflows', :namespace => 'approval').count,
                       'portfolio_items'    => portfolio_items.count,
                       'shared_groups'      => access_control_entries.select(:group_uuid).distinct.count
                     }}
  end
end
