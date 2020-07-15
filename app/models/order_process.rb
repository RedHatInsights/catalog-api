class OrderProcess < ApplicationRecord
  include UserCapabilities
  acts_as_tenant(:tenant)
  acts_as_taggable_on

  belongs_to :before_portfolio_item, :class_name => 'PortfolioItem'
  # belongs_to :after_portfolio_item, :class_name => 'PortfolioItem'
  has_many :tag_links, :dependent => :destroy, :inverse_of => :order_process

  def metadata
    {:user_capabilities => user_capabilities}
  end
end
