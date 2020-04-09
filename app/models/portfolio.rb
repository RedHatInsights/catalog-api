class Portfolio < ApplicationRecord
  include OwnerField
  include Discard::Model
  include Catalog::DiscardRestore
  include Aceable
  include UserCapabilities

  destroy_dependencies :portfolio_items

  before_save { self.statistics = stats }
  after_undiscard { update_statistics }

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
    {:user_capabilities => user_capabilities}.tap do |data|
      data[:statistics] = statistics
    end
  end

  def update_statistics
    current_stats = stats
    return if current_stats.eql?(statistics)

    update(:statistics => current_stats)
  end

  private

  def stats
    {
      'approval_processes' => tags.where(:name => 'workflows', :namespace => 'approval').count,
      'portfolio_items'    => portfolio_items.count,
      'shared_groups'      => access_control_entries.select(:group_uuid).distinct.count
    }
  end
end
