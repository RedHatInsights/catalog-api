class Portfolio < ApplicationRecord
  include OwnerField
  include Discard::Model
  include Api::V1x0::Catalog::DiscardRestore
  include Aceable
  include UserCapabilities
  include Metadata::Ancillary

  MAX_NAME_LENGTH = 512

  destroy_dependencies :portfolio_items

  acts_as_tenant(:tenant)
  acts_as_taggable_on
  default_scope -> { kept.order(Arel.sql('LOWER(portfolios.name)')) }
  belongs_to :icon, :optional => true

  validates :name, :presence => true, :length => {:maximum => MAX_NAME_LENGTH}, :uniqueness => {:scope => %i[tenant_id discarded_at]}
  validates :enabled_before_type_cast, :format => {:with => /\A(true|false)\z/i}, :allow_blank => true

  has_many :portfolio_items, :dependent => :destroy

  def add_portfolio_item(portfolio_item)
    portfolio_items << portfolio_item
  end

  def metadata
    ancillary_metadata.metadata_attributes.merge('user_capabilities' => user_capabilities, 'statistics' => statistics_metadata)
  end

  private

  def update_ancillary_metadata
    ancillary_metadata.statistics = statistics_metadata
  end

  def statistics_metadata
    {
      'approval_processes' => tags.where(:namespace => 'approval', :name => 'workflows').count,
      'portfolio_items'    => portfolio_items.count,
      'shared_groups'      => access_control_entries.count { |ace| ace.permissions.present? }
    }
  end
end
