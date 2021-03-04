class PortfolioItem < ApplicationRecord
  include OwnerField
  include Discard::Model
  include UserCapabilities
  include Api::V1x0::Catalog::DiscardRestore
  include Metadata::Ancillary
  destroy_dependencies :service_plans

  MAX_NAME_LENGTH = 512

  acts_as_tenant(:tenant)
  acts_as_taggable_on

  default_scope -> { kept.order(Arel.sql('LOWER(portfolio_items.name)')) }

  after_create    :update_portfolio_stats
  after_discard   :update_portfolio_stats
  after_undiscard :update_portfolio_stats
  after_destroy   :update_portfolio_stats
  before_discard  :validate_deletable, :prepend => true

  belongs_to :icon, :optional => true
  has_many :service_plans, :dependent => :destroy
  belongs_to :portfolio
  validates :service_offering_ref, :name, :presence => true
  validates :favorite_before_type_cast, :format => {:with => /\A(true|false)\z/i}, :allow_blank => true
  validates :name, :presence => true, :length => {:maximum => MAX_NAME_LENGTH}

  def metadata
    ancillary_metadata.metadata_attributes.merge('user_capabilities' => user_capabilities, 'statistics' => statistics_metadata)
  end

  def validate_deletable
    order_process_names = OrderProcess.where(:before_portfolio_item_id => id).or(OrderProcess.where(:after_portfolio_item_id => id)).pluck(:name)

    unless order_process_names.empty?
      errors.add(:base, "cannot be deleted because it is used by order processes #{order_process_names.uniq}")
      throw :abort
    end
  end

  private

  def update_portfolio_stats
    portfolio.update_metadata
  end

  def statistics_metadata
    {
      'approval_processes' => tags.where(:namespace => 'approval', :name => 'workflows').count
    }
  end

  def deletable?
    tags.where(:name => 'order_processes').count == 0
  end
end
